DOCKER_REPO  ?= rowekamp
MARIADB_CLUSTER ?= sa-test
THREADS ?= 16
IMAGE_NAME := mariadb-test
VERSION := 0.0.4
IMAGE := $(DOCKER_REPO)/$(IMAGE_NAME)

.PHONY: help

help:
	@echo "Usage: make test MARIADB_CLUSTER=<cluster-name>\n       make benchmark MARIADB_CLUSTER=<cluster-name> [THREADS=<threads>]"

build-image:
	build/docker-build.sh "$(IMAGE)" "$(VERSION)"

push-image: build-image
	build/docker-push.sh "$(IMAGE)" "$(VERSION)"

test: push-image
	build/kubernetes-run.sh "$(MARIADB_CLUSTER)" "$(IMAGE):$(VERSION)" test

benchmark: push-image
	build/kubernetes-run.sh "$(MARIADB_CLUSTER)" "$(IMAGE):$(VERSION)" sysbench $(THREADS)

infrastructure-test: push-image
	build/kubernetes-run.sh "$(MARIADB_CLUSTER)" "$(IMAGE):$(VERSION)" infrastructure
