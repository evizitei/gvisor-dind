
FROM debian:bullseye-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    tini \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Get docker keys for verifying later
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc


# install docker ... in docker
RUN echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*
    

# Install gVisor
RUN curl -fsSL https://gvisor.dev/archive.key | gpg --dearmor -o /usr/share/keyrings/gvisor-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gvisor-archive-keyring.gpg] https://storage.googleapis.com/gvisor/releases release main" \
    | tee /etc/apt/sources.list.d/gvisor.list > /dev/null && \
    apt-get update && \
    apt-get install -y runsc && \
    rm -rf /var/lib/apt/lists/*

# Configure Docker to use gVisor
RUN mkdir -p /etc/docker && \
    echo '{"runtimes": {"runsc": {"path": "/usr/bin/runsc"}}}' > /etc/docker/daemon.json

# Create startup script
COPY <<EOF /usr/local/bin/startup.sh
#!/bin/bash
# Start Docker daemon
dockerd &

# Wait for Docker daemon to be ready
while ! docker info >/dev/null 2>&1; do
    echo "Waiting for Docker daemon..."
    sleep 1
done

# Keep container running
exec tail -f /dev/null
EOF

RUN chmod +x /usr/local/bin/startup.sh

# Use tini as init
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/startup.sh"]
