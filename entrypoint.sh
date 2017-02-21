#!/bin/bash -e

[[ $DEBUG == true || $DEBUG == 1 ]] && set -x

# Map user to current UID/GID
export USER_ID="$(id -u)"
export GROUP_ID="$(id -g)"
envsubst < /usr/share/gitolite3/passwd.in > ${HOME}/passwd
export NSS_WRAPPER_PASSWD=${HOME}/passwd
export NSS_WRAPPER_GROUP=/etc/group
export LD_PRELOAD=/usr/lib64/libnss_wrapper.so

# Make sure all new files are writable by group
umask u=rwx,g=rwx,o=rx

# Prepare permissions for Admin user
htpasswd -b -c ${HTPASSWD_FILE} ${ADMIN_USER} ${ADMIN_PASS}

# setup gitolite
mkdir -v -p ${HOME}/repositories
gitolite setup -a ${ADMIN_USER}

## Sed change in gitweb.conf using TEMP File
TFILE=`mktemp --tmpdir tfile.XXXXX`
trap "rm -f $TFILE" 0 1 2 3 15
sed -e "s|.*projectroot.*|our \$projectroot = \"${HOME}/repositories\"|" /etc/gitweb.conf > "${TFILE}" && cat "${TFILE}" > /etc/gitweb.conf && rm "${TFILE}"

# Make gitolite-admin readable by git-daemon
touch ${HOME}/repositories/gitolite-admin.git/git-daemon-export-ok

if [[ $# -ge 1 ]]; then
  echo "$@"
  exec $@
else
  # httpd won't start correctly if it thinks it is already running.
  rm -rf /run/httpd/* /tmp/httpd*

  # Fix for logging on Docker 1.8 (See Docker issue #6880)
  cat <> /var/log/httpd/access_log &
  cat <> /var/log/httpd/error_log 1>&2 &

  echo "Starting HTTPD Gitolite server."
  exec /usr/sbin/apachectl -DFOREGROUND
fi



