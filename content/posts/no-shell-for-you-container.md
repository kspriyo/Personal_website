---
title: "No Shell for You, Container"
date: 2023-12-16T12:44:50-05:00
draft: false
series: []
tags: []
---

Build container images `FROM scratch`, they said. It'll be fun, they said.

<!--more-->

## Difficulties of Minimal Container Images

In your journey to
[build secure container images](https://docs.docker.com/develop/security-best-practices/)
, you've probably stumbled upon a resource that suggested using one of the
following minimal base images.

- [Scratch](https://dev.to/iblancasa/use-scratch-images-is-it-a-good-idea-32lp)
- [Distroless](https://github.com/GoogleContainerTools/distroless)

After some hurdles, you got your application to work with one of these base
images and even deployed your new application container to production.

Then one day something goes wrong. Your application isn't working and you're
flying blind because you still haven't started that backlog ticket to fully
instrument your application using [OpenTelemetry](https://opentelemetry.io/).
Desperate to debug your application, you do what any good engineer would do and
try and get a shell on your container. However, you're greeted with an error and
no shell.

```sh
> podman exec -it helloworld sh
Error: crun: executable file `sh` not found in $PATH: No such file or directory: OCI runtime attempted to invoke a command that was not found
```

Uh-oh. Hopefully we have some error budget left this month.

## Building a Minimal Container Image

Before we learn how to debug the application container, let's build an example
application container using distroless as the base image.

The example application will be an HTTP server written in [Go](https://go.dev)
that responds to any HTTP request with `Hello, World!`.

Go ahead an initialize a new Go module.

```sh
go mod init helloworld
```

Then create a `main.go` file with the following content.

```go
package main

import (
	"log"
	"net/http"
	"os"
)

const defaultAddr = ":8080"

func main() {
	// Support a configurable listen address.
	addr := os.Getenv("HELLOWORLD_ADDR")
	if addr == "" {
		addr = defaultAddr
	}

    // An HTTP handler that logs each request and responds with `Hello, World!`.
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("connection received: path=%s method=%s", r.URL.Path, r.Method)
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Hello, World!"))
	})

	// Start the HTTP server and wait for requests.
	log.Printf("http server started: addr=%s", addr)
	if err := http.ListenAndServe(addr, handler); err != nil {
		log.Fatalln(err)
	}
}
```

Next, create a `Dockerfile`, or `Containerfile` for the Podman users, with the
following content.

```dockerfile
# Builder stage.
FROM golang:1.21-bookworm AS builder
WORKDIR /usr/src/helloworld
COPY go.mod ./
RUN go mod download && go mod verify
COPY . ./
RUN CGO_ENABLED=0 go build -o /usr/local/bin/helloworld ./...

# Final stage.
FROM gcr.io/distroless/static-debian12
COPY --from=builder /usr/local/bin/helloworld /usr/local/bin/helloworld
ENTRYPOINT ["/usr/local/bin/helloworld"]
```

Build the application container image.

```sh
podman build -t localhost/helloworld:latest .
```

Run the application container.

```sh
podman run --rm -it \
  --publish 8080:8080 \
  --name helloworld \
  localhost/helloworld:latest
```

In another terminal session, make an HTTP request to the application to verify
that the application is correctly running.

```sh
> curl http://localhost:8080
Hello, World!
```

In that new terminal session, try to get a shell in the application container.
You'll receive an error and be unable to get a shell.

```sh
> podman exec -it helloworld sh
Error: crun: executable file `sh` not found in $PATH: No such file or directory: OCI runtime attempted to invoke a command that was not found
```

Perfect, we're ready to debug!

## Debugging with Sidecar Containers

Even though we can't get a shell in the application container, we can still
debug it using a sidecar container. A sidecar container is nothing more than a
container that shares access to the same resources as another container. What
resources, exactly? PID and network namespaces, mainly.

In the Kubernetes world, a
[sidecar container](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/)
is run in the same pod as another container. We're not using Kubernetes in this
example, but we can still create a sidecar container and attach it to the same
resources as the application container.

Let's create an Ubuntu container and attach it to the same PID and network
namespaces as the application container.

```sh
podman run --rm -it \
  --pid container:helloworld \
  --network container:helloworld \
  ubuntu:latest
```

Install some debugging tools inside the new container.

```sh
root@5a0f61f5a4d8:/# apt update && apt install -y iproute2 file
```

Now we can use these debugging tools to get some information about the
application container.

We can list processes and see the `helloworld` process is successfully running.

```sh
root@5a0f61f5a4d8:/# ps
    PID TTY          TIME CMD
      1 pts/0    00:00:00 helloworld
      8 pts/0    00:00:00 bash
    581 pts/0    00:00:00 ps
```

We can list information about network sockets and see the `helloworld` process
is listening on TCP port 8080.

```sh
root@5a0f61f5a4d8:/# ss -plnt
State          Recv-Q         Send-Q                 Local Address:Port                 Peer Address:Port        Process
LISTEN         0              4096                               *:8080                            *:*            users:(("helloworld",pid=1,fd=3))
```

We can even browse files on the filesystem of the application container.

```sh
root@5a0f61f5a4d8:/# file /proc/1/root/usr/local/bin/helloworld
/proc/1/root/usr/local/bin/helloworld: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=m_ZjLmQc9E6XDzUFE2pu/phVDJXSQW6cVa0uVbdi7/pLH3R4ED3b_7H3R2lP1w/aeuE-YzaCrbLpqL2P8fG, with debug_info, not stripped
```

The best part is that all of this access is enabled without modifying the
application container image. When we're done debugging we can remove the sidecar
container and leave no trace or side effects behind.

Pretty neat, huh?
