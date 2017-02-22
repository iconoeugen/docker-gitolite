# iconoeugen/docker-gitolite

A docker image to run Gitolite

> Gitolite website: [gitolite.com](http://gitolite.com/gitolite/index.html)
> GitWeb website: [git-scm.com](https://git-scm.com/docs/gitweb)

## Quick start

### Clone this project:

``` bash
git clone https://github.com/iconoeugen/docker-gitolite
cd docker-gitolite
```

### Make your own GitWeb image

Build your image:

``` bash
docker build -t dockergitolite_gitolite .
```

Run your image:

``` bash
docker run --name dockergitolite_test -p 8080:80 --detach dockergitolite_gitolite
```

Check running container:

``` bash
git ls-remote http://localhost:8080/git/testing.git
```

Stop running container:

``` bash
docker stop dockergitolite_test
```

Remove stopped container:

``` bash
docker rm dockergitolite_test
```

## Docker compose

Compose is a tool for defining and running multi-container Docker applications, using a Compose file  to configure
the application services.

Build docker images:

``` bash
docker-compose build
```

Create and start docker containers with compose:

``` bash
docker-compose up -d
```

Stop docker containers

``` bash
docker-compose stop
```

Removed stopped containers:

``` bash
docker-compose rm
```

## Environment Variables

- **ADMIN_USER**: Admin user name. Defaults to `admin`.
- **ADMIN_PASS**: Admin user password. Defaults to `password`.

### Set your own environment variables

Environment variables can be set by adding the --env argument in the command line, for example:

``` bash
docker run --env ADMIN_USER="administrator" --env ADMIN_PASS="changeme" --name dockergitolite_test -p 8080:80 --detach dockergitolite_gitolite
```

To clone the default `testing` repository from the container started before, use the command:

``` bash
git clone http://localhost:8080/git/testing.git
```

Note: you may include the ".git" at the end but it is optional.

## OpenShift

OpenShift Origin is a distribution of Kubernetes optimized for continuous application development and multi-tenant deployment.

More information:
- https://www.openshift.org/
- https://github.com/openshift/origin

The OpenShift *Gitolite application template* is available in *openshift*

### Upload template to OpenShift

Create a new template application in OpenShift (before continue, make sure you are logged in and a new project is created in OpenShift)

``` bash
oc create -f openshift/gitolite.json
```

### Create application from template

``` bash
oc new-app gitolite -p ADMIN_USER=admin -p ADMIN_PASS=changeme
```

## Tests

Access the GitWeb UI at: http://localhost:8080/git

Push content to the new empty repository:

``` bash
mkdir testing
cd testing
git init
touch README
git add README
git commit -m "First commit"
git remote add test http://admin:password@localhost:8080/git/testing.git
git push test master
```

### Logging

The installation will write logging files in two different locations depending one the application that generates the
log events:

* httpd: redirected to docker output
* gitolite: `/var/lib/gitolite3/.gitolite/logs/gitolite-<year>-<month>.log`

## Managing gitolite

The complete documentation about gitolite can be found [here](http://gitolite.com/gitolite/gitolite.html)

### Update configuration

The configuration for gitolite is stored in a git repository named `gitolite-admin`. All changes that are done to this
configuration is automatically applied after a git push using a post-commit hook. To clone the git repository run the
command:

```
git clone http://admin:password@172.17.0.2:8080/git/gitolite-admin
```

Make gitolite-admin readable by git-daemon until a first commit to ensure you can access gitolite-admin.git repo
after first commit (POST_COMMIT trigger) give read access to 'daemon' user (see http://gitolite.com/gitolite/gitweb-daemon.html):

```
repo gitolite-admin
    RW+     =   admin
    R       =   daemon
```

### Add rule to allow to create "wild" repositories

Add at the beginning of `conf/gitolite.conf` to following configuration to allow all users that have valid credentials to create a new repository:

```
repo pub/..*
    C       =   @all
    RW+     =   CREATOR
    RW      =   WRITERS
    R       =   READERS
```

When trying to clone a respository that doesn't exists yeat,
the configuration above will create a new one and configure as `CREATOR` the user that made the request:

```
git clone http://admin:password@172.17.0.2:8080/git/pub/myrepo
```

The new repository can be cloned only after the permissions for read have been granted to some user/group:

```
curl http://admin:password@172.17.0.2:8080/git/perms?pub/myrepo+%2B+WRITERS+@all
```

See more info [here](http://gitolite.com/gitolite/wild.html)

### Gitolite shell commands

Gitolite is providing features that are accessible as shell commands. The command name will come just after the /git/, followed by a ?, followed by the arguments, with + representing a space.

The get a list of all enabled features, call:

```
curl http://admin:password@172.17.0.2:8080/git/help
```

To get information about a specific command, call:

```
curl http://admin:password@172.17.0.2:8080/git/info?-h
```

See more info [here](http://gitolite.com/gitolite/http.html)
