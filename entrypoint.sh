#!/usr/bin/env bash
set -euo pipefail

: "${USERNAME:=runner}"
: "${PASSWORD:=changeme}"
: "${USER_UID:=1001}"
: "${USER_GID:=1001}"
: "${SSH_PORT:=22}"

# Create group/user if missing
if ! getent group "${USER_GID}" >/dev/null; then
  groupadd -g "${USER_GID}" "${USERNAME}"
fi
if ! id -u "${USERNAME}" >/dev/null 2>&1; then
  useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /bin/bash "${USERNAME}"
fi

echo "${USERNAME}:${PASSWORD}" | chpasswd

# Harden a bit
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?Port .*/Port '"${SSH_PORT}"'/' /etc/ssh/sshd_config
mkdir -p /home/"${USERNAME}"/.ssh && chmod 700 /home/"${USERNAME}"/.ssh && chown -R "${USERNAME}:${USER_GID}" /home/"${USERNAME}"/.ssh

exec /usr/sbin/sshd -D -e