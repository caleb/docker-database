#!/usr/bin/env bash

command=$1
shift

TIMEOUT=${TIMEOUT:-60} # Number of attempts at connecting before timing out

#
# Set up MySQL credentials
#
export MYSQL_PWD=$DB_PASSWORD
mysql_config_editor set --user=$DB_USERNAME --host=$DB_HOSTNAME --port=${DB_PORT:-3306}

#
# Set up the PostgreSQL credentials
#
# hostname:port:database:username:password
echo "$DB_HOSTNAME:${DB_PORT:-5432}:*:$DB_USERNAME:$DB_PASSWORD" >> ~/.pgpass
chmod u=rw,g=,o= ~/.pgpass
export PGHOST=$DB_HOSTNAME
export PGPORT=${DB_PORT:-5432}
export PGUSER=$DB_USERNAME
export PGDATABASE=$DB_NAME

#
# Wait until the host is up
#
((count = $TIMEOUT))
while [[ $count -ne 0 ]]; do
  ping -c 1 ${DB_HOSTNAME} >> /dev/null 2>&1
  rc=$?
  if [[ $rc -eq 0 ]]; then
    ((count = 1))
  else
    sleep 1
  fi
  ((count = count - 1))
done

if [[ $rc -ne 0 ]] ; then
  echo "Could not connect to host $DB_HOSTNAME"
  exit 1
fi

#
# Wait until the database is ready
#
searching=true
((count = $TIMEOUT))
while [ $searching = "true" ]; do
  mysqladmin ping --silent
  mysql_rc=$?
  pg_isready --quiet
  postgres_rc=$?

  if [ $mysql_rc -eq 0 ]; then
    searching=false
    export DB_KIND=mysql
  elif [ $postgres_rc -eq 0 ]; then
    searching=false
    export DB_KIND=postgres
  elif [[ $count -eq 0 ]]; then
    searching=false
  else
    ((count = count - 1))

    sleep 1
  fi
done

if [ $DB_KIND = "postgres" ] || [ $DB_KIND = "mysql" ]; then
  echo "Connected to $DB_KIND on $DB_HOSTNAME successfully!"
else
  echo "Could not connect to either a MySQL or PostgreSQL database on $DB_HOSTNAME"
  exit 1
fi

if [ $command = 'exec' ]; then
  # Run an arbitrary command line argument
  exec "${@}"
fi
