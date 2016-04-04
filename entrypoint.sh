#!/bin/bash

export HOME=${GITOLITE_HTTP_HOME}
export HTPASSWD_FILE=${HOME}/htpasswd
export GL_USER=${ADMIN_USER}

export GITOLITE_HTTP_HOME=${GITOLITE_HTTP_HOME:-/var/lib/gitolite3}
export GIT_PROJECTS_LIST=${GITOLITE_HTTP_HOME}/projects.list
export GIT_PROJECT_ROOT=${GITOLITE_HTTP_HOME}/repositories

htpasswd -b -c ${HTPASSWD_FILE} ${ADMIN_USER} ${ADMIN_PASS}

# setup gitolite
gitolite setup -a ${ADMIN_USER}

# Make gitolite-admin readable by git-daemon
touch ${GITOLITE_HTTP_HOME}/repositories/gitolite-admin.git/git-daemon-export-ok

# httpd won't start correctly if it thinks it is already running.
rm -rf /run/httpd/* /tmp/httpd*

exec /usr/sbin/apachectl -DFOREGROUND
