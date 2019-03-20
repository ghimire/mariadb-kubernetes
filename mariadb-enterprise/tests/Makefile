DOCKER_REPO  ?= gcr.io/dbaas-development
MARIADB_CLUSTER ?= sa-test
THREADS ?= 16
IMAGE_NAME := mariadb-ssb-test
VERSION := 0.0.1
IMAGE := $(DOCKER_REPO)/$(IMAGE_NAME)

## SSB specific params
#! Prepequisite - CS topology contating NFS mount should be available 
# SAMPLE :
#general cluster parameters
  #cluster:
    #id: null                                     # e.g. "1"
    #topology: columnstore                        # possible values "masterslave", "standalone", "galera", "columnstore", "columnstore-standalone" 
  #.....
  #server:
    #.... 
    #backup:
      #nfs:
        #server: 10.12.0.136                      # NFS server hostname or ip
        #path: /                                  # NFS path to mount
      #restoreFrom: null                          # name of restore subdirectory
#
NFS_SERVER_IP ?= 10.12.0.136
DATA_SCALE_FACTOR ?= 2  #scale factor (SF) - determines the size of the test tables .Table size = inital rows count * (SF). Inital fact size = 600000 rows,inital dimension size (1k:30k)

SSB_POD_SUFFUX ?= ssb-test #ssb designated pod responsible for generating ColumnStore extracts set
SSB_DIR ?= ssb #ssb scripts dir

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

#SSB specific targets
build-ssb-image:
	ssb-cs-tests/build/docker-build.sh "$(IMAGE)" "$(VERSION)" "$(DATA_SCALE_FACTOR)"

push-ssb-image: build-ssb-image
	ssb-cs-tests/build/docker-push.sh "$(IMAGE)" "$(VERSION)"

deploy-ssb-image: push-ssb-image
	ssb-cs-tests/build/kubernetes-deploy.sh "$(MARIADB_CLUSTER)" "$(IMAGE):$(VERSION)"  "$(SSB_POD_SUFFUX)" "$(NFS_SERVER_IP)"

load-ssb-test: deploy-ssb-image
	ssb-cs-tests/build/load-test.sh "$(MARIADB_CLUSTER)" "$(SSB_POD_SUFFUX)" 

power-ssb-test: load-ssb-test
	ssb-cs-tests/build/power-test.sh "$(MARIADB_CLUSTER)" "$(SSB_DIR)"

throughput-ssb-test: load-ssb-test
	ssb-cs-tests/build/throughput-test.sh "$(MARIADB_CLUSTER)" "$(SSB_DIR)"