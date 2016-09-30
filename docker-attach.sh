#!/bin/sh -eu

DID="$(docker ps | grep 'cytopia/mysql-5.5' | awk '{print $1}')"
docker exec -i -t ${DID} /bin/bash

