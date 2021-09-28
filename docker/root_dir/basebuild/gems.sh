#!/bin/bash

set -e
source /basebuild/buildconfig
set -x

gem update --system ${GEM_VERSION}
gem install bundler --version ${BUNDLER_VERSION}
cd ${WORKPATH} && bundle install --jobs `grep -c ^processor /proc/cpuinfo`
