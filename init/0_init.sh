#!/bin/bash

cat <<EOF > /flyway/conf/flyway.conf
flyway.url=jdbc:mysql://127.0.0.1/faf?localSocket=/var/run/mysqld/mysqld.sock
flyway.user=root
flyway.password=${MYSQL_ROOT_PASSWORD}
EOF

./flyway/flyway migrate || exit 1;
