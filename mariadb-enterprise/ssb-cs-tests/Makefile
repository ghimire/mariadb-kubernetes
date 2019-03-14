MARIADB_CLUSTER ?= nedpk-cs
SSB_POD_SUFFUX ?= ssb-test

DOCKER_REPO ?= gcr.io/dbaas-development
IMAGE_NAME ?= mariadb-cs-ssb
VERSION ?= 0.0.12
IMAGE := $(DOCKER_REPO)/$(IMAGE_NAME)

THREADS ?= 16 
DATA_SCALE_FACTOR ?= 150  #the scale factor (SF)  determines the size of the tables (in GB)

SSB_DIR ?= ssb



.PHONY: help

help:
	@echo "Usage: make test MARIADB_CLUSTER=<cluster-name>  DATA_SCALE_FACTOR=2 \n       make benchmark MARIADB_CLUSTER=<cluster-name> [THREADS=<threads>]"

build-image:
	build/docker-build.sh "$(IMAGE)" "$(VERSION)" "$(DATA_SCALE_FACTOR)"

push-image: build-image
	build/docker-push.sh "$(IMAGE)" "$(VERSION)"

deploy-image: push-image
	build/kubernetes-deploy.sh "$(MARIADB_CLUSTER)" "$(IMAGE):$(VERSION)"  "$(SSB_POD_SUFFUX)"

load-test: deploy-image
	build/load-test.sh "$(MARIADB_CLUSTER)" "$(SSB_POD_SUFFUX)" 

power-test: load-test
	build/power-test.sh "$(MARIADB_CLUSTER)" "$(SSB_DIR)"

throughput-test: load-test
	build/throughput-test.sh "$(MARIADB_CLUSTER)" "$(SSB_DIR)"