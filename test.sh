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

if [ -n "$INPUT_DOCKER_NETWORK_ID" ]; then
    RUN_NETWORK="--network=$INPUT_DOCKER_NETWORK_ID"
fi

echo $RUN_NETWORK
