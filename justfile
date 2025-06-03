#!/usr/bin/env just --justfile


IMAGE_NAME := 'ghcr.io/zotero-custom/dataserver'

# List available recipes
default:
  @just --list

build:
  docker image build -t {{ IMAGE_NAME }}:latest .

sh:
  docker run --rm -it \
    --name zotero-dataserver \
    -p 8080:80 \
    -v ./tests/:/var/www/zotero/tests/ \
    -e BASE_URI=http://localhost:8080/ \
    -e API_BASE_URI=http://localhost:8080/ \
    -e WWW_BASE_URI=http://localhost:8080/ \
    -e API_SUPER_USERNAME=admin \
    -e API_SUPER_PASSWORD=admin \
    -e AUTH_SALT=mysecretsalt \
    -e AWS_ENDPOINT_URL_S3=http://minio:9000 \
    -e AWS_ACCESS_KEY_ID=zotero \
    -e AWS_SECRET_ACCESS_KEY=zoterodocker \
    -e AWS_DEFAULT_REGION=us-east-1 \
    -e REDIS_HOST=redis \
    -e MEMCACHED_SERVERS=memcached:11211 \
    -e HTMLCLEAN_SERVER_URL=http://tinymce-clean-server:16342 \
    -e LOCALSTACK_SERVER_URL=http://localstack:4566 \
    --hostname localhost.localdomain \
    {{ IMAGE_NAME }}:latest 'bash'

