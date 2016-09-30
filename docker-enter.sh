#!/bin/sh -eu

# Run
docker run -i \
	--entrypoint /bin/bash \
	--env MYSQL_ROOT_PASSWORD="" \
	-t cytopia/mysql-5.5

