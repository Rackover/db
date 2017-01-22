#!/usr/bin/env bash

DB_CONTAINER=faf-db
DB_NAME=faf
DUMP_SCHEMA=
HOST_LOCATION=
spin='-\|/'
spin_index=0

rotate_loading_spinner() {
    spin_index=$(( (spin_index+1) % 4 ))
    printf "\r${spin:$spin_index:1}"
}

show_help() {
    printf "Usage: ./setup_db.sh [options]
       ./setup_db.sh -c /tmp/dump.sql
       ./setup_db.sh -c /tmp

Options:
    -d         Dump DB schema to container STDOUT.
    -c <file>  Dump DB schema to provided file location. If a directory is provided, the file name will be dump.sql.
    -h         Print script command line options.\n"
    exit 1;
}

while getopts ":dc:h" opt; do
  case $opt in
    d)
      DUMP_SCHEMA=1
      ;;
    c)
      HOST_LOCATION=$OPTARG
      ;;
    h)
      show_help
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1;
      ;;
  esac
done

docker build -t ${DB_CONTAINER} . || exit 1;
docker run -d --name ${DB_CONTAINER} -e MYSQL_ROOT_PASSWORD=banana -p 3306:3306 ${DB_CONTAINER} || exit 1;

# Run faf-db image in a new container and waits until it initialized
echo "Creating database '${DB_NAME}'..."
until docker exec -i ${DB_CONTAINER} mysql -uroot -pbanana -e "select 1;" > /dev/null;
do
  rotate_loading_spinner
  sleep 1;
done
printf "\nSuccessfully created database '${DB_NAME}'";

if [ $DUMP_SCHEMA ]; then
  docker exec -i ${DB_CONTAINER} mysqldump -uroot -pbanana --no-data ${DB_NAME} || exit 1;
fi

if [ $HOST_LOCATION ]; then
  docker exec -i ${DB_CONTAINER} /bin/sh -c "mysqldump -uroot -pbanana --no-data ${DB_NAME} > /tmp/dump.sql" || exit 1;
  docker cp ${DB_CONTAINER}:/tmp/dump.sql ${HOST_LOCATION} || exit 1;
  docker exec -i ${DB_CONTAINER} rm -f /tmp/dump.sql || exit 1;
  echo "Schema copied to ${HOST_LOCATION}"
fi

docker exec -i ${DB_CONTAINER} mysql -uroot -pbanana ${DB_NAME} < test-data.sql || exit 1;
