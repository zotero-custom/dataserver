#!/usr/bin/env just --justfile

# List available recipes
default:
  @just --list

build:
  docker image build -t $IMAGE_NAME:latest .

sh:
  docker run --rm -it --env-file {{source_dir()}}/.env --entrypoint bash $IMAGE_NAME:latest