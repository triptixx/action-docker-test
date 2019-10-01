#!/bin/sh
set -eo pipefail

# ANSI colour escape sequences
RED='\033[0;31m'
RESET='\033[0m'
error() { >&2 echo -e "${RED}Error: $@${RESET}"; }

verbose() { test "$INPUT_VERBOSE" = true -o "$INPUT_VERBOSE" = 1; }

# $INPUT_REPO          tag for the image to run and test
# $INPUT_DELAY         startup delay for the container before curl'ing it
# $INPUT_RETRY         curl retry count before giving up
# $INPUT_RETRY_DELAY   curl delay before retrying
# $INPUT_PIPE          shell code to execute on curl output. useful for ensuring output correctness
# $INPUT_CURL_OPTS     additional options to pass to curl
# $INPUT_RUN_ARGS      arguments to pass to `docker create`
# $INPUT_RUN_CMD       override docker container CMD
# $INPUT_RUN           override docker container CMD, with sh -c

if [ -z "$INPUT_REPO" ]; then
    error "Missing 'repo' argument required for testing"
fi

DELAY=${INPUT_DELAY:-10}
RETRY=${INPUT_RETRY:-5}
RETRY_DELAY=${INPUT_RETRY_DELAY:-5}
TIMEOUT=${INPUT_TIMEOUT:-10}

# If not curling an only piping logs, don't wait
if [ -z "$INPUT_CURL" -a -n "$INPUT_LOG_PIPE" ]; then
    DELAY=0
fi

if [ -n "$DOCKER_NETWORK_ID" ]; then
    RUN_NETWORK="--network=$DOCKER_NETWORK_ID"
fi


# If INPUT_RUN is provided, just run the command in the container and exit
if [ -n "$INPUT_RUN" ]; then
    if verbose; then
        RUN_DBG=x
        set -x
    fi

    exec docker run --rm --entrypoint= $RUN_NETWORK $INPUT_RUN_ARGS "$INPUT_REPO" sh -c$RUN_DBG "$INPUT_RUN"
fi

# Start the container
CONTAINER_ID="$(if verbose; then set -x; fi; docker create --rm $RUN_NETWORK $INPUT_RUN_ARGS "$INPUT_REPO" $INPUT_RUN_CMD)"

# Start the container and print the logs
# and exit if the container stops
trap 'docker kill $CONTAINER_ID >/dev/null 2>/dev/null' EXIT
trap 'error "The container exited unexpectedly :("; exit 10' USR1
( docker start --attach --interactive "$CONTAINER_ID" ; kill -s USR1 $$ ) &

# Get container IP, hopefully before the container exits
sleep 1
CONTAINER_IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_ID)"
if [ -z "$CONTAINER_IP" ]; then
    trap ':' USR1
    docker kill "$CONTAINER_ID" >/dev/null 2>&1 || true
    docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true
    error 'No container IP found'
    exit 8
fi

(
if [ ${DELAY} -eq 0 ]; then exit 0; fi
if verbose; then set -x; fi

# Wait
sleep $DELAY
)

# Run pre-curl script
if [ -n "$INPUT_EXEC_PRE" ]; then
    set +e
    if verbose; then DEBUG=-x; fi
    echo $INPUT_EXEC_PRE | docker exec -i "$CONTAINER_ID" sh $DEBUG
    retval=$?
    set -e

    if [ $retval != 0 ]; then
        error "Pre script exited with $retval"
        exit $retval
    fi
fi

if [ -n "$INPUT_LOG_PIPE" ]; then
    set +e
    if verbose; then PIPE_DBG=x; fi
    timeout ${TIMEOUT} \
        docker logs -f $CONTAINER_ID 2>&1 | (sh -c$PIPE_DBG "${INPUT_LOG_PIPE}" && pkill -PIPE timeout) # this is a horrible hack
    retval=$?
    set -e

  # 141 is 128 + 13 (SIGPIPE), caused by (pkill induced) pipefail. This indicates success
    if [ $retval != 141 ]; then
        if [ $retval == 124 ]; then
            error "Log output parsing timed out after ${TIMEOUT}s"
            exit $retval
        elif [ $retval != 0 ]; then
            error "Log output parsing exited with $retval"
            exit $retval
        fi
    fi
fi

# Attempt to curl
if [ -n "$INPUT_CURL" ]; then
    (
    if verbose; then set -x; fi

    curl -L \
        --retry $RETRY \
        --retry-delay $RETRY_DELAY \
        --retry-max-time 10 \
        --retry-connrefused \
        $INPUT_CURL_OPTS \
        "$CONTAINER_IP$INPUT_CURL" \
        > /tmp/output
    )

    if verbose; then
        cat /tmp/output
    fi
fi

# Test the output
if [ -n "$INPUT_CURL" -a -n "$INPUT_PIPE" ]; then
    set +e
    if verbose; then set -x; fi

    eval $INPUT_PIPE < /tmp/output
    retval=$?
    set -e
    set +x

    if [ $retval != 0 ]; then
        error "Pipe exited with $retval"
        exit $retval
    fi
fi
rm -f /tmp/output

# Run post-curl script
if [ -n "$INPUT_EXEC_POST" ]; then
    set +e
    if verbose; then DEBUG=-x; fi
    echo $INPUT_EXEC_POST | docker exec -i "$CONTAINER_ID" sh $DEBUG
    retval=$?
    set -e

    if [ $retval != 0 ]; then
        error "Post script exited with $retval"
        exit $retval
    fi
fi

# Prevent error exiting when the container is removed
trap ':' USR1
