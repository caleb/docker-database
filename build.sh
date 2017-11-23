#!/usr/bin/env bash

TAG=1.0

docker build --tag=caleb/database:$TAG .
docker tag caleb/database:$TAG caleb/database:latest
