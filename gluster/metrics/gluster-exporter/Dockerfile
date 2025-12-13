FROM quay.io/centos/centos:stream9 AS builder

RUN dnf -y update \
 && dnf -y install git golang make gcc \
 && dnf clean all

WORKDIR /src
RUN git clone --depth 1 https://github.com/gluster/gluster-prometheus.git
WORKDIR /src/gluster-prometheus

ENV GO111MODULE=off
RUN go build -o /out/gluster-exporter ./gluster-exporter

FROM ghcr.io/gluster/gluster-containers:centos

RUN yum -y install curl && yum clean all || true

COPY --from=builder /out/gluster-exporter /usr/local/bin/gluster-exporter
EXPOSE 9713
ENTRYPOINT ["/usr/local/bin/gluster-exporter"]
