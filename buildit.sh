#!/bin/bash

[ -d "$(pwd)/leshan" ] || (git clone https://github.com/eclipse/leshan.git && cd $(pwd)/leshan)
sed -i '/leshan-integration-tests/d' pom.xml

if docker ps -a | grep -q leshan-clean; then
    docker start -a leshan-clean
else
    docker run -it --name leshan-clean -v "$PWD":/usr/src/mymaven -w /usr/src/mymaven maven:onbuild mvn clean
fi

if docker ps -a | grep -q leshan-clean; then
    docker start -a leshan-build
else
    docker run -it --name leshan-build -v "$PWD":/usr/src/mymaven -w /usr/src/mymaven maven:onbuild mvn install
fi
