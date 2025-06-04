#!/bin/sh

# Original source:
#   https://github.com/victoradrianjimenez/dockerized-zotero/blob/master/dataserver/init/init-mysql.sh

MYSQL="mysql -h mysql -P 3306 -u $MYSQL_USER --password=$MYSQL_PASSWORD"
SCRIPTS_DIR='/var/www/zotero/misc'

if [ $(echo "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'zotero_master'" | $MYSQL -s -N) -eq 0 ]; then
echo "DROP DATABASE IF EXISTS zotero_master" | $MYSQL
echo "CREATE DATABASE zotero_master" | $MYSQL

# Load in master schema
$MYSQL zotero_master < $SCRIPTS_DIR/master.sql
$MYSQL zotero_master < $SCRIPTS_DIR/coredata.sql
$MYSQL zotero_master < $SCRIPTS_DIR/fulltext.sql

# Set up shard info
echo "INSERT INTO shardHosts (shardHostID, address, port, state) VALUES (1, 'mysql', 3306, 'up');" | $MYSQL zotero_master
echo "INSERT INTO shards (shardID, shardHostID, db, state) VALUES (1, 1, 'zotero_shard_1', 'up');" | $MYSQL zotero_master
echo "INSERT INTO shards (shardID, shardHostID, db, state) VALUES (2, 1, 'zotero_shard_2', 'up');" | $MYSQL zotero_master

# Initial users and groups for tests
echo "INSERT INTO libraries (libraryID, libraryType, shardID) VALUES (1, 'user', 1)" | $MYSQL zotero_master
echo "INSERT INTO libraries (libraryID, libraryType, shardID) VALUES (2, 'group', 2)" | $MYSQL zotero_master
echo "INSERT INTO users (userID, libraryID, username) VALUES (1, 1, 'admin')" | $MYSQL zotero_master
echo "INSERT INTO \`groups\`(groupID, libraryID, name, slug, libraryEditing, libraryReading, fileEditing, description, url) VALUES (1, 2, 'Shared', 'shared', 'admins', 'all', 'members', '', '') " | $MYSQL zotero_master
echo "INSERT INTO groupUsers (groupID, userID, role) VALUES (1, 1, 'owner')" | $MYSQL zotero_master
fi


if [ $(echo "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'zotero_shard_1'" | $MYSQL -s -N) -eq 0 ]; then
echo "DROP DATABASE IF EXISTS zotero_shard_1" | $MYSQL
echo "CREATE DATABASE zotero_shard_1" | $MYSQL

# Load in shard schema
cat /var/www/zotero/misc/shard.sql | $MYSQL zotero_shard_1
cat /var/www/zotero/misc/triggers.sql | $MYSQL zotero_shard_1

echo "INSERT INTO shardLibraries (libraryID, libraryType) VALUES (1, 'user')" | $MYSQL zotero_shard_1
fi


if [ $(echo "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'zotero_shard_2'" | $MYSQL -s -N) -eq 0 ]; then
echo "DROP DATABASE IF EXISTS zotero_shard_2" | $MYSQL
echo "CREATE DATABASE zotero_shard_2" | $MYSQL

# Load in shard schema
cat /var/www/zotero/misc/shard.sql | $MYSQL zotero_shard_2
cat /var/www/zotero/misc/triggers.sql | $MYSQL zotero_shard_2

echo "INSERT INTO shardLibraries (libraryID, libraryType) VALUES (2, 'group')" | $MYSQL zotero_shard_2
fi


if [ $(echo "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'zotero_ids'" | $MYSQL -s -N) -eq 0 ]; then
echo "DROP DATABASE IF EXISTS zotero_ids" | $MYSQL
echo "CREATE DATABASE zotero_ids" | $MYSQL

# Load in schema on id servers
$MYSQL zotero_ids < /var/www/zotero/misc/ids.sql
fi


if [ $(echo "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'zotero_www'" | $MYSQL -s -N) -eq 0 ]; then
echo "DROP DATABASE IF EXISTS zotero_www" | $MYSQL
echo "CREATE DATABASE zotero_www" | $MYSQL

# Load in www schema
$MYSQL zotero_www < $SCRIPTS_DIR/www.sql

echo "INSERT INTO users (userID, username, password) VALUES (1, 'admin', MD5('admin'))" | $MYSQL zotero_www
echo "INSERT INTO users_email (userID, email) VALUES (1, 'admin@zotero.org')" | $MYSQL zotero_www
echo "INSERT INTO storage_institutions (institutionID, domain, storageQuota) VALUES (1, 'zotero.org', 10000)" | $MYSQL zotero_www
echo "INSERT INTO storage_institution_email (institutionID, email) VALUES (1, 'contact@zotero.org')" | $MYSQL zotero_www
fi


# TODO: the schema_update script is in dataserver://admin/schema_update.
#       We'll need to run this from the dataserver after the mysql startup is complete
# Run schema updates
cd /var/www/zotero/admin
./schema_update


# Master my.cnf:
#
# [mysqld]
# server-id = 1
# datadir = /usr/local/var/mysql/master
# socket = /usr/local/var/mysql/master/mysql.sock
# port = 3307
# log-bin = binary_log
# innodb_flush_log_at_trx_commit = 1
# sync_binlog = 1
# innodb_file_per_table
# default-character-set = utf8
# sql_mode = STRICT_ALL_TABLES
# default-time-zone = '+0:00'
# event_scheduler = ON
# 
#
# Shard my.cnf:
#
# [mysqld]
# server-id = 10
# datadir = /usr/local/var/mysql/shard
# socket = /usr/local/var/mysql/shard/mysql.sock
# port = 3308
# innodb_flush_log_at_trx_commit = 1
# sync_binlog = 1
# innodb_file_per_table
# default-character-set = utf8
# sql_mode = STRICT_ALL_TABLES
# default-time-zone = '+0:00'
#
# ID my.cnf:
#
# [mysqld]
# datadir = /usr/local/var/mysql/id
# socket = /usr/local/var/mysql/id/mysql.sock
# port = 3309
# slow_query_log = 1
# key_buffer_size = 512K
# max_allowed_packet = 1M
# table_cache = 32
# read_buffer_size = 100K
# sort_buffer_size = 100K
# read_rnd_buffer_size = 100K
# myisam_sort_buffer_size = 100K
# thread_cache_size = 50
# query_cache_size = 1M
# max_connections = 200
# sql_mode = STRICT_ALL_TABLES
# default-time-zone = '+0:00'
# character-set-server = utf8
# skip-innodb
# 
# id1:
#
# auto-increment-increment = 2
# auto-increment-offset = 1
#
# id2:
#
# auto-increment-increment = 2
# auto-increment-offset = 2


# ./test_setup
