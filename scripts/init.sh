#!/bin/sh

DRUPAL_RESTORE_FILE=${DRUPAL_RESTORE_FILE:-drupal_default.sql}

MYSQL_HOST=${MYSQL_HOST:-mariadb}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

MYSQL_DATABASE=${MYSQL_DATABASE:-drupal_default}

function check_db_exists {
    mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -e "use ${MYSQL_DATABASE};" > /dev/null 2>&1
}

function create_database {
    if $DEBUG; then
	echo "Creating Database"
    fi
    mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -e "create database ${MYSQL_DATABASE}"
}

function create_db_if_not_exists {
    if ! check_db_exists; then
	create_database
    fi
}

function reset_root_password {
    mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} -e "set password for 'root'@'%' = PASSWORD('${MYSQL_ROOT_PASSWORD}');"
}

function check_table_exists {
    mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} ${MYSQL_DATABASE} -e "select * from users limit 1;" > /dev/null 2>&1
}

function restore_database_from_file {
    if $DEBUG; then
	echo "Restoring from File"
    fi
    mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} ${MYSQL_DATABASE} < /var/lib/mysql-files/${DRUPAL_RESTORE_FILE}
}

function set_default_user_pass {
    if [ -z ${DRUPAL_DEFAULT_DB_PASSWORD} ]
    then
    	if $DEBUG; then
		echo "Not setting password"
	fi
    else
       if $DEBUG; then
       		echo "Setting default user password"
	fi
	mysql -u root -p${MYSQL_ROOT_PASSWORD} -h ${MYSQL_HOST} -P ${MYSQL_PORT} ${MYSQL_DATABASE} -e "grant ALL PRIVILEGES on ${MYSQL_DATABASE}.* to '${DRUPAL_DEFAULT_DB_USER}'@'%' identified by '${DRUPAL_DEFAULT_DB_PASSWORD}';"
    fi;
}

reset_root_password
create_db_if_not_exists
set_default_user_pass

if ! check_table_exists; then
    if $DEBUG; then
	echo "Need to bootstrap database"
    fi
    restore_database_from_file
fi
