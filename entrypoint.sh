#!/usr/bin/env bash
set -Eeuo pipefail

[[ ! -f /etc/ssh/ssh_host_dsa_key ]] && ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
[[ ! -f /etc/ssh/ssh_host_ecdsa_key ]] && ssh-keygen -q -N "" -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
[[ ! -f /etc/ssh/ssh_host_ed25519_key ]] && ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
[[ ! -f /etc/ssh/ssh_host_rsa_key ]] && ssh-keygen -q -N "" -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key

[[ ! -f /etc/passwd ]] && mv /etc/passwd2 /etc/passwd
[[ ! -f /etc/group ]] && mv /etc/group2 /etc/group
[[ ! -f /etc/ssh/sshd_config ]] && mv /etc/ssh/sshd_config2 /etc/ssh/sshd_config

exec /usr/sbin/sshd "$@"
