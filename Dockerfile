FROM ubuntu:16.04

MAINTAINER Caleb Land <caleb@land.fm>

# Install some software
RUN apt-get update \
&&  apt-get install -y postgresql-client mysql-client iputils-ping \
&&  rm -rf /var/lib/apt/lists/*

ADD rootfs/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
# CMD [""]
