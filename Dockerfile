FROM golang:1.13

ENV GO111MODULE=on

RUN apt-get update
RUN apt-get install -y libnss3-dev libx11-dev vim git unzip build-essential autoconf libtool

RUN git clone https://github.com/google/protobuf.git && \
    cd protobuf && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    ldconfig && \
    make clean && \
    cd .. && \
    rm -r protobuf

RUN mkdir -p /go/src/github.com/Arnold1/tfs-client
ADD ./main.go /go/src/github.com/Arnold1/tfs-client
ADD ./tfclient /go/src/github.com/Arnold1/tfs-client/tfclient
ADD ./Makefile /go/src/github.com/Arnold1/tfs-client
WORKDIR /go/src/github.com/Arnold1/tfs-client

RUN git clone -b r1.13 --depth 1 https://github.com/tensorflow/serving.git
RUN git clone -b r1.13 --depth 1 https://github.com/tensorflow/tensorflow.git

RUN go get -u github.com/golang/protobuf/proto
RUN go get -u github.com/golang/protobuf/protoc-gen-go
RUN go get -u google.golang.org/grpc

RUN go mod init github.com/Arnold1/tfs-client

#RUN make clean; make bindings; make all

CMD ["/bin/bash"]
