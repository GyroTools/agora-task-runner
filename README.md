# Agora Task Runner (SSH-enabled utility container)

A minimal Ubuntu 24.04 image with OpenSSH server and common tooling (python3, pip, venv, curl, git, bash) intended to act as a task-runner addon for Agora (or any Docker Compose–based deployment). The container configures an SSH user from environment variables and keeps `sshd` in the foreground.

## Features
- Ubuntu 24.04 base
- OpenSSH server
- Python 3 + pip + venv, `scipy`, `numpy`, `requests`, `psutil`, `gtagora-connector`
- Env-driven user creation (username/password/UID/GID/port)
- Runs `sshd` in the foreground (suitable for containers)

## Environment variables
| Variable     | Default   | Description                                     |
|--------------|-----------|-------------------------------------------------|
| `USERNAME`   | `runner`  | SSH username                                    |
| `PASSWORD`   | `changeme`| SSH password (set this!)                        |
| `UID`        | `1001`    | UID to assign if available                      |
| `GID`        | `1001`    | GID to assign if available                      |
| `SSH_PORT`   | `22`      | SSH daemon listen port inside the container     |

> If `UID`/`GID` are already taken in the base image, the entrypoint will still attempt to use them unless you override to a free UID/GID.

## Quick start (docker run)
```bash
docker run -d --name task-runner \
  -e USERNAME=runner \
  -e PASSWORD=secret123 \
  -e UID=1001 \
  -e GID=1001 \
  -e SSH_PORT=22 \
  -p 2222:22 \
  gyrotools/agora-task-runner:latest
```
Then SSH from the host:
```bash
ssh runner@localhost -p 2222
```

## Docker Compose examples

### Exposed to host (for debugging/admin)
```yaml
services:
  task-runner:
    image: gyrotools/agora-task-runner:latest
    environment:
      USERNAME: runner
      PASSWORD: secret123
      UID: "1001"
      GID: "1001"
      SSH_PORT: "22"
    ports:
      - "2222:22"
    healthcheck:
      test: ["CMD-SHELL", "nc -z localhost 22"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
```

### Internal-only (no host exposure)
```yaml
services:
  task-runner:
    image: gyrotools/agora-task-runner:latest
    environment:
      USERNAME: runner
      PASSWORD: secret123
      UID: "1001"
      GID: "1001"
      SSH_PORT: "22"
    expose:
      - "22"
    networks:
      - internal_net
    restart: unless-stopped

networks:
  internal_net:
    driver: bridge
    internal: true
```
Other services on `internal_net` can reach it via `task-runner:22`; the host cannot connect because no port is published.

## Building locally
```bash
docker build -t agora-task-runner:local .
docker run --rm -p 2222:22 -e USERNAME=runner -e PASSWORD=secret123 agora-task-runner:local
```

## Notes and recommendations
- Change the default password before use.
- If you don’t need host access, avoid publishing the port; use `expose` + internal networks.
- Consider mounting authorized keys and disabling password auth for stronger security.
- Healthchecks are recommended (as shown above) so orchestrators can report status.
- Host SSH keys are regenerated on each container start; if you want stable host keys, mount `/etc/ssh` from a volume.
