#!/bin/sh

echo "SELECT 1;" | mysql --user="root" --password="${MYSQL_ROOT_PASSWORD}" > /dev/null

exit $?
