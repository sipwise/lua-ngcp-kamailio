# DOCKER_NAME=lua-ngcp-kamailio-jessie
FROM docker.mgm.sipwise.com/sipwise-jessie:latest

# Important! Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT 2016-12-2

# TODO - the release-trunk-jessie is too dynamic yet, though required for lua-unit backport
RUN echo "deb https://deb.sipwise.com/autobuild/ release-trunk-jessie main" >>/etc/apt/sources.list

RUN apt-get update && apt-get install --assume-yes lua5.1 lua-unit lua-lemock lua-logging python-xmlrunner

RUN echo './t/testrunner' >>/root/.bash_history

# Create files with mode 666 and folders with mode 777 which
# allows to delete the temporary files (aka results) for
# non-root users (like 'jenkins' or 'developer's laptop local user')
RUN echo 'umask 0' >>/root/.bashrc

WORKDIR /code/

################################################################################
# Instructions for usage
# ----------------------
# When you want to build the base image from scratch (jump to the next section if you don't want to build yourself!):
# % docker build --tag="lua-ngcp-kamailio-jessie" .
# % docker run --rm -i -t -v $(pwd)/..:/code:rw lua-ngcp-kamailio-jessie:latest bash
#
# Use the existing docker image:
# % docker pull docker.mgm.sipwise.com/lua-ngcp-kamailio-jessie
# % docker run --rm -i -t -v $(pwd)/..:/code:rw docker.mgm.sipwise.com/lua-ngcp-kamailio-jessie:latest bash
#
# Inside docker (the command is in history, just press UP button):
#   ./t/testrunner
#
################################################################################
