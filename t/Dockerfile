# DOCKER_NAME=lua-ngcp-kamailio-buster
FROM docker.mgm.sipwise.com/sipwise-buster:latest

# Important! Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT 2019-10-01

# files that get-code generates
COPY t/sources.list.d/builddeps.list /etc/apt/sources.list.d/
COPY t/sources.list.d/preferences /etc/apt/preferences.d/

RUN apt-get update && apt-get install --assume-yes \
	lua5.1 lua-unit lua-cjson lua-curl lua-lemock lua-logging \
	lua-argparse lua-check \
	python3-pytest

RUN echo './t/testrunner' >>/root/.bash_history

WORKDIR /code/

################################################################################
# Instructions for usage
# ----------------------
# When you want to build the base image from scratch
# jump to the next section if you don't want to build yourself!:
#
# you need to put the proper NGCP sources at t/sources.list.d/builddeps.list
# for instance, trunk:
# echo "deb https://deb.sipwise.com/autobuild/ release-trunk-buster main" > t/sources.list.d/builddeps.list
#
# % docker build --tag="lua-ngcp-kamailio-buster" -f t/Dockerfile .
# % docker run --rm -i -t -v $(pwd):/code:rw lua-ngcp-kamailio-buster:latest bash
#
# Use the existing docker image:
# % docker pull docker.mgm.sipwise.com/lua-ngcp-kamailio-buster
# NOTE: run the following command from root folder of git repository:
# % docker run --rm -i -t -v $(pwd):/code:rw docker.mgm.sipwise.com/lua-ngcp-kamailio-buster:latest bash
#
# Inside docker (the command is in history, just press UP button):
#   ./t/testrunner
#
################################################################################
