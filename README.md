# action-docker-test
A plugin for [Actions CI](https://github.com/features/actions) to start and test build docker images

## Configuration

An example configuration of how the plugin should be configured:
```yaml
steps:
  - name: publish
    uses: triptixx/action-docker-publish@master
    with:
      docker_username: docker_username
      docker_password: docker_password
      from: image-name-dev
      repo: user/image-name:optional-tag
      tags: docker_tag,over_docker_tag
    args: '--tags'
```

### Available options
- `verbose`        print curl output and running commands. _default: `false`_
- `repo`           docker 'password' for pushing. _required_
- `delay`          startup delay for the container before executing any actions. _default: `10`_
- `retry`          curl retry count before giving up. _default: `5`_
- `retry_delay`    curl delay before retrying. _default: `5`_
- `timeout`        timeout to `docker container logs`. _default: `10`_
- `run`            run a command in a test container and exit. _optional_
- `run_args`       arguments to pass to `docker container create` _optional_. _default: `latest`_
- `run_cmd`        override docker container CMD. _optional_
- `curl`           url path to curl e.g. `:8080/directory`. _default: `latest`_
- `curl_opts`      . _default: `latest`_
- `pipe`           . _default: `latest`_
- `log_pipe`       . _default: `latest`_
- `exec_pre`       . _default: `latest`_
- `exec_post`      . _default: `latest`_
