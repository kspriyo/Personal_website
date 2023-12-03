FROM golang:1.21.4

# Install curl.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Hugo.
ENV HUGO_VERSION=0.120.4
RUN curl -L -o /tmp/hugo.tar.gz https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz && \
    tar -xvf /tmp/hugo.tar.gz -C /usr/local/bin hugo && \
    rm -rf /tmp/hugo.tar.gz

# Build the Hugo site.
WORKDIR /app
COPY . .
RUN hugo --destination public
