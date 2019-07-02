###############################################################################
# Instructions for usage (run commands from root folder of this git repository)
###############################################################################
#
# Pull and run the existing docker image:
#
# % docker pull docker.mgm.sipwise.com/lua-ngcp-kamailio-buster:latest
# % docker run --rm -i -t -v $(pwd):/code:rw docker.mgm.sipwise.com/lua-ngcp-kamailio-buster:latest bash
#
# Inside docker (the command is in history, just press UP button):
#   ./t/testrunner
#
###############################################################################
#
# When you want to build the base image from scratch:
#
# you need to put the proper NGCP sources at t/sources.list.d/builddeps.list, for instance, trunk:
# % echo "deb https://deb.sipwise.com/autobuild/ release-trunk-buster main" > t/sources.list.d/builddeps.list
# OR mr7.5.1:
# % echo "deb https://deb.sipwise.com/spce/mr7.5.1/ buster main" > t/sources.list.d/builddeps.list
#
# Build local Docker image:
# % docker build --tag="lua-ngcp-kamailio-buster" -f t/Dockerfile .
# Hint: use '--no-cache' option if you want to force all layers rebuilding.
#
# Run Docker container locally:
# % docker run --rm -i -t -v $(pwd):/code:rw lua-ngcp-kamailio-buster:latest bash
#
# Inside docker (the command is in history, just press UP button):
#   ./t/testrunner
#
###############################################################################

# Important! Update REFRESHED_AT variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ARG REFRESHED_AT=2019-06-27
ARG DEBIAN_FLAVOR=buster
ARG SIPWISE_REGISTRY=docker.mgm.sipwise.com
ARG IMAGE_TAG=latest
ARG BASE_IMAGE=sipwise-$DEBIAN_FLAVOR
ARG MAINTAINER=development@sipwise.com
ARG DOCKER_NAME=lua-ngcp-kamailio-${DEBIAN_FLAVOR}
ARG NGCP_VERSION=trunk
## Jenkins jobs are grepping this label to fetch/run necessary container by name.
# DOCKER_NAME=lua-ngcp-kamailio-buster

FROM ${SIPWISE_REGISTRY}/${BASE_IMAGE}:${IMAGE_TAG}
LABEL Description="This image to run lua-kamailio.git unit tests" Vendor="Sipwise" Version="${NGCP_VERSION}"
MAINTAINER $MAINTAINER

# files that get-code generates
COPY t/sources.list.d/builddeps.list /etc/apt/sources.list.d/
COPY t/sources.list.d/preferences /etc/apt/preferences.d/

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install --assume-yes \
    lua5.1 \
    lua-unit \
    lua-cjson \
    lua-curl \
    lua-lemock \
    lua-logging \
    lua-argparse \
    lua-check \
    python-xmlrunner \
    && \
  apt-get clean

RUN echo './t/testrunner' >>/root/.bash_history

WORKDIR /code/
