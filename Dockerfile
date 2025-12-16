FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install SSH server and common tools
RUN apt-get update && apt-get install -y \
    openssh-server \
    python3 \
    python3-pip \
    python3-venv \
    bash \
    curl \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install needed Python packages (optional)
RUN pip3 install --break-system-packages --no-cache-dir \
    scipy \
    numpy \
    requests \    
    psutil \
    gtagora-connector

# Create SSH directory
RUN mkdir /var/run/sshd
RUN rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

# Copy entrypoint that wires env → user/password/sshd_config
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose SSH port
EXPOSE 22
CMD ["/entrypoint.sh"]
