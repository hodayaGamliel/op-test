#!/bin/bash

source envs.sh
echo $backend_url

#docker build -t v4-stage4 -f Dockerfile1 .
docker build -t v4-op --build-arg backend_url=$backend_url --build-arg secret_key=$secret_key -f Dockerfile1 .
#docker build -t david3 --build-arg backend_url=$backend_url --build-arg secret_key=$secret_key -f Dockerfile3 .
#docker build -t david4 --build-arg backend_url=$backend_url --build-arg secret_key=$secret_key -f Dockerfile4 .
