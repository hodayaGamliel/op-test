#!/bin/bash

#cd /home/ubuntu/change-times; ./change.sh
cleanc
cleani

cd /home/ubuntu/v4-op/docker-gc-cron; docker run -d -v /var/run/docker.sock:/var/run/docker.sock  clockworksoul/docker-gc-cron

cd /home/ubuntu/v4-op; ./build.sh

cd /home/ubuntu/v4-op; ./run.sh

#cd /home/ubuntu/v4-op; ./run.sh
#cd /home/ubuntu/v4-op; ./run.sh
#cd /home/ubuntu/v4-op; ./run.sh
