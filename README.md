lanparty-packages - packaging infra for ansible-lanparty
===

This repository contains the build infrastructure for the software deployed
using [ansible-lanparty](https://github.com/ti-mo/ansible-lanparty). It is
inspired by [Codeship build infrastructure](https://blog.codeship.com/using-docker-build-debian-packages) and is Debian-oriented. Builds are run
in Docker containers using [fpm-cookery](https://github.com/bernd/fpm-cookery)
or simply using Rake where applicable.

It sets out to achieve the following goals:

- Reproducible package builds that (sort of) allow for continuous integration
- Allows us to apply hotfixes to critical pieces of our infrastructure safely
- Applying customizations to Debian or upstream packages
- Distribute our own software using Debian packages
- etc.

## Requirements

Since all build environments run containerized, there are no external
dependencies but `docker-compose`, which takes care of setting environment
variables and invoking the right commands when starting containers.

- Docker (>= 1.11.0)
- docker-compose

# Building

## Building the Docker images

First, build the images in the correct order:

```
$ docker-compose build baseimg
$ docker-compose build kernelimg
```

Make sure this completes successfully. Check installed images using:

```
$ docker images
REPOSITORY          TAG    IMAGE ID       CREATED          SIZE
lanparty-packages   kernel 167d349357f0   15 seconds ago   2.248 GB
lanparty-packages   base   b9aa1afa3990   5 minutes ago    866.4 MB
```

## Building Packages

To build a specific package, run:

`docker-compose run <package>`

Available options are:

- consul
- joki
- nginx
- nginx-git (builds ti-mo/nginx)
- php
- kernel-ck-tick
- kernel-ck-notick

Check `docker-compose.yml` for all available options.

The output of the package build processes can be found in `pkg/`.

# Distributing

This section assumes you have an Aptly API set up, which is beyond the scope
of this README.

## Setting up the API client

Download an Aptly CLI client. (we use [Ruby aptly_cli](https://github.com/sepulworld/aptly_cli)) Configure your credentials in `/etc/aptly-cli.conf`.
An alternative config location can be provided with the `-c` flag.

```yml
# /etc/aptly-cli.conf
---
:proto: https
:server: <your-aptly-api>
:port: 443
:debug: false
:username: <username>
:password: <password>
```

Verify connectivity:

```
$ aptly-cli repo_list
{}
```

Looks good!

## Creating an Aptly repo

Create the repository itself:

`aptly-cli -c aptly-cli.conf repo_create --name lanparty`

Publish repository with both x86 architectures (i386 and amd64):

`aptly-cli publish_repo --name lanparty --sourcekind local --distribution lanparty --architectures i386,amd64 --prefix .`

## Uploading

This heading (Uploading) and the next (Publishing) are to be repeated for every
batch of packages you want to add to the repository. This allows for atomic
transactions, for example, when uploading a bunch of dependant packages.

Upload a .deb file to a directory of choice. (mind the leading /)

`aptly-cli file_upload --upload influxdb_1.0.2_amd64.deb --directory /lanparty-incoming`

List uploaded files in `lanparty-incoming`:

`aptly-cli file_list --directory lanparty-incoming`

## Publishing

Rotate uploaded files into repository:

`aptly-cli repo_upload --dir lanparty-incoming --name lanparty`

Update the published repository with:

`aptly-cli publish_update --distribution lanparty`

# Useful

## Dropping a published repo

Does what it says on the tin, drops the published version of the repo
(but keeps the repo itself around!):

`aptly-cli publish_drop --name lanparty`

## Updating a published repo

Update a published repo, mostly used for changing the key of the GPG ID to
sign the repo with:

`aptly-cli publish_update --distribution lanparty --gpg_key 466665F8`

Or to change the prefix:

`aptly-cli publish_update --distribution lanparty --prefix .`

## Deleting a (file) folder

Even though files get moved out of directories when invoking `repo_upload`,
the directories itself will stick around. Run the following to delete a file
or a whole directory. (for example when uploading files to temporary
directories with timestamps, etc.)

`aptly-cli file_delete --target /lanparty-incoming`
