# action-docker-test
A plugin for [Actions CI](https://github.com/features/actions) to start and test build docker images

## Configuration

An example configuration of how the plugin should be configured:
```yaml
steps:
  - name: publish
    uses: triptixx/action-docker-test@master
    with:
      repo: test-me:latest
      retry: 5
      curl: ':8080/healthcheck'
      pipe: grep -qw 'online'
      exec_post: |
        grep -q 'teststring' /var/thing/file; another-command
```

### Available options
- `verbose`        print curl output and running commands. _default: `false`_
- `repo`           docker 'password' for pushing. _required_
- `delay`          startup delay for the container before executing any actions. _default: `10`_
- `retry`          curl retry count before giving up. _default: `5`_
- `retry_delay`    curl delay before retrying. _default: `5`_
- `timeout`        timeout to `docker container logs`. _default: `10`_
- `run`            run a command in a test container and exit. _optional_
- `run_args`       arguments to pass to `docker container create` _optional_
- `run_cmd`        override docker container CMD. _optional_
- `curl`           url path to curl e.g. `:8080/directory`. _optional_
- `curl_opts`      additional options to pass to curl. _optional_
- `pipe`           shell code to execute on curl output. useful for ensuring output correctness. _optional_
- `log_pipe`       shell code to execute on `docker container logs` output. _optional_
- `exec_pre`       shell commands inside the container to run before curl. _optional_
- `exec_post`      shell commands inside the container to run after curl. _optional_
