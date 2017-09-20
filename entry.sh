#!/usr/bin/env bash

set -e

[ "$DEBUG" == 'true' ] && set -x

DAEMON=vsftpd

#Setting PASV parameters
echo ">> Setting PASV parameters"
if [ -n "$PASV_MAX" ]; then
  augtool -s 'set /files/etc/vsftpd/vsftpd.conf/pasv_max_port' $PASV_MAX
  if [ -n "$PASV_MIN" ]; then
    augtool -s 'set /files/etc/vsftpd/vsftpd.conf/pasv_min_port' $PASV_MIN
    if [ -n "$PASV_ADDRESS" ]; then
      augtool -s 'set /files/etc/vsftpd/vsftpd.conf/pasv_address' $PASV_ADDRESS
    else
      echo "!! PASV_ADDRESS not set, setup failed!"
      exit 1
    fi
  else
    echo "!! PASV_MIN not set, setup failed!"
    exit 1
  fi
else
  echo "!! PASV_MAX not set, setup failed!"
  exit 1
fi

# Create FTP users
if [ -n "${FTP_USERS}" ]; then
  USERS=$(echo $FTP_USERS | tr "," "\n")
  for U in $USERS; do
    IFS=':' read -ra FU <<< "$U"
    _NAME=${FU[0]}
    _PASS=${FU[1]}
    _UID=${FU[2]}
    _GID=${FU[3]}

    echo ">> Adding user ${_NAME} with uid: ${_UID}, gid: ${_GID}."
    getent group ${_NAME} >/dev/null 2>&1 || addgroup -g ${_GID} ${_NAME}
    getent passwd ${_NAME} >/dev/null 2>&1 || adduser -D -u ${_UID} -G ${_NAME} -s '/bin/false' ${_NAME}
    echo "${_NAME}:${_PASS}" | /usr/sbin/chpasswd

    # Add directory symlinks for users
    if [[ -n "${SYMLINK}" ]]; then
      augtool -s 'set /files/etc/vsftpd/vsftpd.conf/chroot_local_user NO'
      DIRS=$(echo $SYMLINK | tr "," "\n")
      for D in $DIRS; do
          IFS=':' read -ra DS <<< "$D"
          _DIR=${DS[0]}
          _DST=${DS[1]}

          echo ">> Creating symbolic link /home/${_NAME}/${_DST} for ${_DIR}"
          if [ ! -d "/home/${_NAME}/${_DST}" ]; then
              ln -s ${_DIR} /home/${_NAME}/${_DST}
          fi
      done
    else
      augtool -s 'set /files/etc/vsftpd/vsftpd.conf/chroot_local_user YES'
    fi
  done
else
  echo "!! FTP_USERS not set, setup failed!"
  exit 1
fi

# Setup vsftpd configuration variables
printf "%s\n" \
  "set /files/etc/vsftpd/vsftpd.conf/local_enable YES" \
  "set /files/etc/vsftpd/vsftpd.conf/allow_writeable_chroot YES" \
  "set /files/etc/vsftpd/vsftpd.conf/ftpd_banner ${FTP_BANNER}" \
  "set /files/etc/vsftpd/vsftpd.conf/dirmessage_enable YES" \
  "set /files/etc/vsftpd/vsftpd.conf/max_clients 10" \
  "set /files/etc/vsftpd/vsftpd.conf/max_per_ip 5" \
  "set /files/etc/vsftpd/vsftpd.conf/write_enable YES" \
  "set /files/etc/vsftpd/vsftpd.conf/local_umask 022" \
  "set /files/etc/vsftpd/vsftpd.conf/passwd_chroot_enable YES" \
  "set /files/etc/vsftpd/vsftpd.conf/pasv_enable YES" \
  "set /files/etc/vsftpd/vsftpd.conf/listen_ipv6 NO" \
  "set /files/etc/vsftpd/vsftpd.conf/anonymous_enable NO" \
  "set /files/etc/vsftpd/vsftpd.conf/seccomp_sandbox NO" \
| augtool -s

# Catch stop signals
stop() {
    echo "Received SIGINT or SIGTERM. Shutting down $DAEMON"
    # Get PID
    pid=$(cat /var/run/$DAEMON/$DAEMON.pid)
    # Set TERM
    kill -SIGTERM "${pid}"
    # Wait for exit
    wait "${pid}"
    # All done.
    echo "Done."
}

echo "Running $@"
if [ "$(basename $1)" == "$DAEMON" ]; then
    trap stop SIGINT SIGTERM
    $@ &
    pid="$!"
    mkdir -p /var/run/$DAEMON && echo "${pid}" > /var/run/$DAEMON/$DAEMON.pid
    wait "${pid}" && exit $?
else
    exec "$@"
fi
