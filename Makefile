.PHONY: build bin clean tfs-client

#CGO_LDFLAGS := "-L$(CURDIR)/lib -Wl,-rpath -Wl,\$ORIGIN/../lib"
PROTOC_OPTS := "-I tensorflow -I serving --plugin=protoc-gen-gogofast --go_out=plugins=grpc:vendor"
SHELL := /bin/bash
timestamp := $(shell date +"%s")
version := $(strip $(timestamp))
build_time := $(shell date +"%Y%m%d.%H%M%S")
build_sha := $(shell git rev-parse --verify HEAD)
goos = $(shell go env GOOS)

repo_name = $(shell basename `pwd`)
pkg_name = github.com/Arnold1/$(repo_name)
ldflags = -ldflags "-X $(pkg_name)/build.time=$(build_time) -X $(pkg_name)/build.number=$(version) -X $(pkg_name)/build.sha=$(build_sha)"
#build_command = GOOS=$(goos) CGO_LDFLAGS=$(CGO_LDFLAGS) go build $(ldflags) -o
build_command = GOOS=$(goos) GO111MODULE=on go build -mod=vendor $(ldflags) -o
list = go list ./... | grep -v vendor/ | grep -v tools/

short_sha := $(shell git rev-parse --short $(shell git rev-parse --verify HEAD))
binary_name ?= tfs-client

all: bin tfs-client

bin:
	mkdir -p bin

clean:
	rm -rf ./bin
	rm -rf ./vendor

tf-client: bin
	$(build_command) bin/$(binary_name)

bindings:
	mkdir -p vendor

	eval "protoc ${PROTOC_OPTS} serving/tensorflow_serving/apis/*.proto"
	eval "protoc $(PROTOC_OPTS) serving/tensorflow_serving/config/*.proto"
	eval "protoc ${PROTOC_OPTS} serving/tensorflow_serving/core/*.proto"
	eval "protoc $(PROTOC_OPTS) serving/tensorflow_serving/util/*.proto"
	eval "protoc $(PROTOC_OPTS) serving/tensorflow_serving/sources/storage_path/*.proto"
	eval "protoc $(PROTOC_OPTS) tensorflow/tensorflow/core/framework/*.proto"
	eval "protoc $(PROTOC_OPTS) tensorflow/tensorflow/core/example/*.proto"
	eval "protoc $(PROTOC_OPTS) tensorflow/tensorflow/core/lib/core/*.proto"
	eval "protoc $(PROTOC_OPTS) tensorflow/tensorflow/core/protobuf/{saver,meta_graph}.proto"
