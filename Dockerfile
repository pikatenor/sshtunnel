FROM golang:1 AS builder

ENV GOFLAGS="-mod=vendor"

WORKDIR /src

COPY ./go.mod ./
COPY ./go.sum ./
RUN go mod download

COPY . ./
RUN go mod vendor
RUN go build --tags netgo --ldflags 'extflags=-static' -o sshtunnel ./cmd/tunnel/main.go

FROM amazon/aws-cli
RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "/tmp/session-manager-plugin.rpm" \
 && yum install -y /tmp/session-manager-plugin.rpm \
 && rm /tmp/session-manager-plugin.rpm
COPY --from=builder /src/sshtunnel /
ENTRYPOINT ["/sshtunnel"]
