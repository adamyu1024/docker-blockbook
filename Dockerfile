FROM debian:9

ENV TAG=master

RUN echo \
    deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib\
    deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib\
    deb http://mirrors.aliyun.com/debian-security stretch/updates main\
    deb-src http://mirrors.aliyun.com/debian-security stretch/updates main\
    deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib\
    deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib\
    deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib\
    deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib\
    > /etc/apt/sources.list

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential git wget pkg-config lxc-dev libzmq3-dev \
                       libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev \
                       liblz4-dev graphviz && \
    apt-get clean

ENV GOLANG_VERSION=go1.14.2.linux-amd64
ENV ROCKSDB_VERSION=v5.18.3

USER root

ENV HOME=/home/blockbook
ENV GOPATH=$HOME/go
ENV PATH="$PATH:$GOPATH/bin"

# install and configure go
RUN cd /opt && wget https://dl.google.com/go/$GOLANG_VERSION.tar.gz && \
    tar xf $GOLANG_VERSION.tar.gz
RUN ln -s /opt/go/bin/go /usr/bin/go
RUN mkdir -p $GOPATH
RUN echo -n "GO version: " && go version
RUN echo -n "GOPATH: " && echo $GOPATH

RUN go env -w GO111MODULE=on
RUN go env -w GOPROXY=https://goproxy.io,direct

# Install RocksDB and the Go wrapper
RUN cd $HOME && git clone -b $ROCKSDB_VERSION --depth 1 https://github.com/facebook/rocksdb.git
RUN cd $HOME/rocksdb && CFLAGS=-fPIC CXXFLAGS=-fPIC make release
RUN strip $HOME/rocksdb/ldb $HOME/rocksdb/sst_dump && \
    cp $HOME/rocksdb/ldb $HOME/rocksdb/sst_dump /build
# install build tools
RUN go get github.com/gobuffalo/packr/...

ENV CGO_CFLAGS="-I/$HOME/rocksdb/include"
ENV CGO_LDFLAGS="-L/$HOME/rocksdb -ldl -lrocksdb -lstdc++ -lm -lz -lbz2 -lsnappy -llz4"

# Install Blockbook
RUN cd $GOPATH/src && git clone https://github.com/adamyu1024/blockbook.git && cd blockbook && git checkout $TAG && \
         BUILDTIME=$(date --iso-8601=seconds); GITCOMMIT=$(git describe --always --dirty); \
         LDFLAGS="-X blockbook/common.version=${TAG} -X blockbook/common.gitcommit=${GITCOMMIT} -X blockbook/common.buildtime=${BUILDTIME}" && \
         go build -ldflags="-s -w ${LDFLAGS}"

# Copy startup scripts
COPY launch.sh $HOME

COPY blockchain_cfg.json $HOME

EXPOSE 9036 9136

ENTRYPOINT $HOME/launch.sh
