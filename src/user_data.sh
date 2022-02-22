#!/bin/bash

# Here we force OpenSSH to allow the use of RSA keys.
#
# See https://github.com/cisagov/cool-system-internal/issues/105 for
# more details.

cat > /etc/ssh/sshd_config.d/99-allow-rsakeys.conf << ENDOFFILE
HostKeyAlgorithms +ssh-rsa
PubkeyAcceptedKeyTypes +ssh-rsa
ENDOFFILE
