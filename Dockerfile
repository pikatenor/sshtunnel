FROM --platform=$BUILDPLATFORM golang:1 AS builder

ENV GOFLAGS="-mod=vendor"

WORKDIR /src

COPY ./go.mod ./
COPY ./go.sum ./
RUN go mod download

ARG TARGETOS
ARG TARGETARCH

COPY . ./
RUN go mod vendor
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0 go build --tags netgo --ldflags 'extflags=-static' -o sshtunnel ./cmd/tunnel/main.go


FROM amazon/aws-cli

ARG TARGETPLATFORM
RUN sh -c " \
case ${TARGETPLATFORM} in \
  linux/amd64) \
    yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm \
    ;; \
  linux/arm64) \
    yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_arm64/session-manager-plugin.rpm \
    ;; \
esac \
"

COPY --from=builder /src/sshtunnel /

ENTRYPOINT ["/sshtunnel"]
