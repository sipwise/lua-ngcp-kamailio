# DOCKER_NAME=lua-ngcp-kamailio-jessie
FROM docker.mgm.sipwise.com/sipwise-jessie:master

# Important! Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT 2016-04-26

# TODO - the release-trunk-jessie is too dynamic yet, though required for lua-unit backport
RUN echo "deb https://deb.sipwise.com/autobuild/ release-trunk-jessie main" >>/etc/apt/sources.list

RUN apt-get update && apt-get install --assume-yes lua5.1 lua-unit lua-lemock lua-logging

RUN echo './t/testrunner' >>/root/.bash_history

WORKDIR /code/

################################################################################
# Instructions for usage
# ----------------------
#
# use TAG=${branch}, default: 'master'
#
# When you want to build the base image from scratch (jump to the next section if you don't want to build yourself!):
# % docker build --tag="lua-ngcp-kamailio-jessie:${TAG}" .
# % docker run --rm -i -t -v $(pwd)/..:/code:rw lua-ngcp-kamailio-jessie:${TAG} bash
#
# Use the existing docker image:
# % docker pull docker.mgm.sipwise.com/lua-ngcp-kamailio-jessie:${TAG}
# % docker run --rm -i -t -v $(pwd)/..:/code:rw docker.mgm.sipwise.com/lua-ngcp-kamailio-jessie:${TAG} bash
#
# Inside docker (the command is in history, just press UP button):
#   ./t/testrunner
#
################################################################################
