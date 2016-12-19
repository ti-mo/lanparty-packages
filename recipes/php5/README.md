PHP5-ZTS Build Recipe
===

Built with the help of [this useful Gist](https://gist.github.com/Bo98/c774c3298c0a8f4ca1b8).

# Intro

This is the first recipe in this repository that makes use of Rake to automate
the steps outlined in the guide above. Since upstream (Debian) releases
security patches frequently, we didn't want to have to repeat these steps
(ever). The script we made initially was inadequate and unmaintained.

# Description

The Rakefile provided in this folder has the following tasks:

- build_php5 - get latest php5 source, build with ZTS, install -common and -dev
- build_php5j - build php5-json from source in the resulting ZTS-enabled env
- build_pthreads - get pthreads from Git, compile and package with pthreads.ini
- default - runs all build steps above in the correct order
- clean - deletes `tmp-build/` and `tmp-dest/`
- cleancache - runs `:clean`, deletes `cache/`

All build tasks run `apt-get build-dep` for their target package.

# Parameters

The Rakefile supports these environment variables to control its functionality:

- `PKGDIR` - .deb output directory
