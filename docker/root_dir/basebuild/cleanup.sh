#!/bin/bash

apt-get -qy autoremove && apt-get clean
find /basebuild/ -not \( -name 'basebuild' -or -name 'buildconfig' -or -name 'cleanup.sh' \) -delete
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
truncate -s 0 /var/log/*log
