#!/usr/bin/env bash
set -euo pipefail

: "${USERNAME:=runner}"
: "${PASSWORD:=changeme}"
: "${UID:=1001}"
: "${GID:=1001}"
: "${SSH_PORT:=22}"

# Create group/user if missing
if ! getent group "${GID}" >/dev/null; then
  groupadd -g "${GID}" "${USERNAME}"
fi
if ! id -u "${USERNAME}" >/dev/null 2>&1; then
  useradd -m -u "${UID}" -g "${GID}" -s /bin/bash "${USERNAME}"
fi

echo "${USERNAME}:${PASSWORD}" | chpasswd

# Harden a bit
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?Port .*/Port '"${SSH_PORT}"'/' /etc/ssh/sshd_config
mkdir -p /home/"${USERNAME}"/.ssh && chmod 700 /home/"${USERNAME}"/.ssh && chown -R "${USERNAME}:${GID}" /home/"${USERNAME}"/.ssh

exec /usr/sbin/sshd -D -e