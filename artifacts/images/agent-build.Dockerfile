# Build the proxy-agent binary
FROM golang:1.21.5 as builder

# Copy in the go src
WORKDIR /go/src/sigs.k8s.io/apiserver-network-proxy

# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

# We have a replace directive for konnectivity-client in go.mod
COPY konnectivity-client/ konnectivity-client/

# Copy vendored modules
COPY vendor/ vendor/

# Copy the sources
COPY pkg/    pkg/
COPY cmd/    cmd/
COPY proto/  proto/


# Build
ARG ARCH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} go build -mod=vendor -v -a -ldflags '-extldflags "-static"' -o proxy-agent sigs.k8s.io/apiserver-network-proxy/cmd/agent

# Copy the loader into a thin image
FROM gcr.io/distroless/static-debian11
WORKDIR /
COPY --from=builder /go/src/sigs.k8s.io/apiserver-network-proxy/proxy-agent .
ENTRYPOINT ["/proxy-agent"]
