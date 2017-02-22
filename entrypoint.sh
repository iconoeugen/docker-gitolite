#!/bin/bash -e

[[ $DEBUG == true || $DEBUG == 1 ]] && set -x

# Map user to current UID/GID
export HOME=${HOME:-/var/lib/gitolite3}
export USER_ID="$(id -u)"
export GROUP_ID="$(id -g)"
envsubst < /usr/share/gitolite3/passwd.in > ${HOME}/passwd
export NSS_WRAPPER_PASSWD=${HOME}/passwd
export NSS_WRAPPER_GROUP=/etc/group
export LD_PRELOAD=/usr/lib64/libnss_wrapper.so

# Make sure all new files are writable by group
umask u=rwx,g=rwx,o=rx

# Setup gitolite
gitolite setup -a ${ADMIN_USER}

export GL_USER=${ADMIN_USER}
export GL_ADMIN_BASE=$(gitolite query-rc -n GL_ADMIN_BASE)
export GL_REPO_BASE=$(gitolite query-rc -n GL_REPO_BASE)
export GL_BINDIR=$(gitolite query-rc -n GL_BINDIR)
export GL_LIBDIR=$(gitolite query-rc -n GL_REPO_BASE)
export HTPASSWD_FILE="${GL_ADMIN_BASE}/htpasswd"

# Gitweb environment
export GITOLITE_HTTP_HOME=${HOME}
export GIT_PROJECT_ROOT=${GL_REPO_BASE}
export GIT_PROJECTS_LIST="${GITOLITE_HTTP_HOME}/projects.list"

# Prepare permissions for Admin user
htpasswd -m -b -c ${HTPASSWD_FILE} ${ADMIN_USER} ${ADMIN_PASS}

## Sed change in gitweb.conf using TEMP File
TFILE=`mktemp --tmpdir tfile.XXXXX`
trap "rm -f $TFILE" 0 1 2 3 15
sed -e "s|.*projectroot.*|our \$projectroot = \"${GL_REPO_BASE}\"|" /etc/gitweb.conf > "${TFILE}" && cat "${TFILE}" > /etc/gitweb.conf && rm "${TFILE}"

# Make gitolite-admin readable by git-daemon until a first commit
# to ensure you can access gitolite-admin.git repo after first commit (POST_COMMIT trigger)
# give read access to 'daemon' user (see http://gitolite.com/gitolite/gitweb-daemon.html):
#
#    repo gitolite-admin
#        RW+     =   admin
#        R       =   daemon
#
touch ${GL_REPO_BASE}/gitolite-admin.git/git-daemon-export-ok

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



