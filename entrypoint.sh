#!/bin/sh
echo "Starting!..."

# Check if AWS_ENDPOINT_URL_S3 is set
if [ -z "$AWS_ENDPOINT_URL_S3" ]; then
  echo "Error: AWS_ENDPOINT_URL_S3 environment variable is not set"
  exit 1
fi

# Parse the URL
scheme=$(echo "$AWS_ENDPOINT_URL_S3" | grep -o '^https\?')
host_and_port=$(echo "$AWS_ENDPOINT_URL_S3" | sed -e 's/^[^:]*:\/\/\([^\/]*\).*$/\1/')
host=$(echo "$host_and_port" | cut -d: -f1)
port=$(echo "$host_and_port" | cut -d: -f2-)

# If port is not specified, set it to the default port for the scheme
if [ -z "$port" ]; then
  if [ "$scheme" = "https" ]; then
    port=443
  else
    port=80
  fi
fi

# Set the new environment variables
export AWS_S3_SCHEME=$scheme
export AWS_S3_HOST=$host
export AWS_S3_SERVER_PORT=$port

# Print the new environment variables
echo "AWS_S3_SCHEME=$AWS_S3_SCHEME"
echo "AWS_S3_HOST=$AWS_S3_HOST"
echo "AWS_S3_SERVER_PORT=$AWS_S3_SERVER_PORT"

cd /var/www/zotero

# Start rinetd
# (see docs here: https://raw.githubusercontent.com/samhocevar/rinetd/refs/heads/main/index.html)
# Most entries in the configuration file are forwarding rules. 
# The format of a forwarding rule is as follows:
#   bindaddress bindport connectaddress connectport [options...]
# echo "0.0.0.0		$S3_SERVER_PORT		$S3_SERVER_HOST		$S3_SERVER_PORT" > /etc/rinetd.conf
echo "0.0.0.0		9000		minio		9000" > /etc/rinetd.conf
/etc/init.d/rinetd start

# Upgrade database
/init-mysql.sh

# # Start Apache2
# exec apache2 -DNO_DETACH -k start
exec "$@"


# #!/bin/sh

# # Modified from source here:
# #   https://github.com/victoradrianjimenez/dockerized-zotero/blob/master/dataserver/entrypoint.sh

# # Env vars
# export APACHE_RUN_USER=www-data
# export APACHE_RUN_GROUP=www-data
# export APACHE_LOCK_DIR=/var/lock/apache2
# export APACHE_PID_FILE=/var/run/apache2/apache2.pid
# export APACHE_RUN_DIR=/var/run/apache2
# export APACHE_LOG_DIR=/var/log/apache2
# export AWS_ENDPOINT_URL_S3=${AWS_S3_SCHEME}://${AWS_S3_HOST}:${AWS_S3_SERVER_PORT}

# ROOT_DIR=/var/www/zotero

# chmod 777 "$ROOT_DIR/tmp"
# cd "$ROOT_DIR"

# # Check if S3 bucket exists before creating
# if ! aws s3 ls s3://$S3_BUCKET >/dev/null 2>&1; then
#     aws s3 mb s3://$S3_BUCKET
# else
#     echo "Bucket s3://$S3_BUCKET already exists"
# fi

# # Check if S3 fulltext bucket exists before creating
# if ! aws s3 ls s3://$S3_BUCKET_FULLTEXT >/dev/null 2>&1; then
#     aws s3 mb s3://$S3_BUCKET_FULLTEXT
# else
#     echo "Bucket s3://$S3_BUCKET_FULLTEXT already exists"
# fi

# aws --endpoint-url "http://localstack:4576" sns create-topic --name zotero

# # Start rinetd
# # (see docs here: https://raw.githubusercontent.com/samhocevar/rinetd/refs/heads/main/index.html)
# # Most entries in the configuration file are forwarding rules. 
# # The format of a forwarding rule is as follows:
# #   bindaddress bindport connectaddress connectport [options...]
# # echo "0.0.0.0		$S3_SERVER_PORT		$S3_SERVER_HOST		$S3_SERVER_PORT" > /etc/rinetd.conf
# echo "0.0.0.0		$S3_SERVER_PORT		minio		$S3_SERVER_PORT" > /etc/rinetd.conf
# /etc/init.d/rinetd start

# # Upgrade database
# /init-mysql.sh

# # Start Apache2
# exec apache2 -DNO_DETACH -k start