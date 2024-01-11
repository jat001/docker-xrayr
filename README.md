# docker-xrayr

XrayR in Docker container

## Usage

Write your custom config in `conf.d`, and your nodes config in `nodes.d`.

Set `NODES=1,2,3` in `.env`, set `PREFER_V6=1` to use IPv6 first.

## IPv6

Enable IPv6 support for Docker daemon:

See [Docker documentation](https://docs.docker.com/config/daemon/ipv6/) for more information.
