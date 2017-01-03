require_relative 'generic.rb'

# Debian-specific instance variables that persist through method calls
@pkg = nil

# Manages the global variable named @pkg to set
# the context of which package to work on.
def debian_workon_pkg(pkg)
  @pkg = pkg
  puts
  puts '-----'
  log "Working on package #{pkg}"
end

# Run apt-get build-dep for a specific package
# - pkg is the package to install its build dependencies for
# - distro is the target distribution for dependency resolution
# - quiet silences installation output
def debian_build_dep(pkg: @pkg, distro: nil, quiet: true)
  log "Getting build dependencies for package #{pkg}"
  q = quiet ? '> /dev/null 2>&1' : ''
  d = distro ? "-t #{distro}" : ''
  shell %Q{DEBIAN_FRONTEND=noninteractive apt-get -y build-dep #{pkg} #{d} #{q}}
end

# Download a source package to the cache folder
# - pkg is the package to download using 'apt-get source'
# - tar_prefix is the package to look for when conditionally downloading
#    It is used to generate a glob pattern: <tar_prefix>_*.orig.tar.xz
#    The default value is set to the value given to 'pkg'
# - quiet squelches the output of apt-get source
#
# This method sets an extraction cookie when successful.
def debian_get_source(pkg: @pkg, tar_prefix: pkg, quiet: true)
  if not pkg
    raise 'pkg parameter must be given to debian_get_source()'
  end

  pattern = "#{tar_prefix}_*.orig.*"
  tarball = Dir.glob(cachedir/pkg/pattern).last
  q = quiet ? '> /dev/null' : ''

  # Ensure cachedir exists
  cachedir(pkg).mkdir

  if not tarball
    log 'No glob matches found for ' + cachedir/pkg/pattern

    # run apt-get source in cache/
    Dir.chdir cachedir/pkg
    log "Running 'apt-get source' for package #{pkg}"
    shell %Q{DEBIAN_FRONTEND=noninteractive apt-get -y source #{pkg} #{q}}
    log "Silencing 'apt-get source' output for package #{pkg}" if quiet == true
  else
    log "Found source archive at #{tarball}, skipping apt-get source"
  end

  # Ensure builddir exists
  builddir(pkg).mkdir

  if not extractcookie?(pkg)
    log "No extract cookie found for package #{pkg}, copying to " + builddir/pkg

    # Copy source tree from cache to builddir
    FileUtils.cp_r "#{cachedir/pkg}/.", builddir/pkg

    set_extractcookie(pkg)
  else
    log "Extract cookie found at " + builddir/".extractcookie_#{pkg}" + ", skipping"
  end

  # Best effort to guess extracted source directory
  return newpath(Dir.glob(builddir(pkg)/'*/').last)
end

# Executes debuild with the specified number of threads
# - threads is the amount of threads spawned when invoking debuild
# - quiet squelches the build output
# - pkg is the package to build. Automatically set if debian_get_source
#   is run prior to this method in the same run.
#
# This method sets a build cookie when successful.
def debuild(threads: 4, quiet: true, pkg: @pkg)
  if not threads.to_s =~ /^[0-9]+$/
    raise 'amount of threads given to debuild() needs to be an integer'
  end

  if not pkg
    raise 'pkg attribute not given, nor could it be inferred from context'
  end

  log "Entering debuild for package #{pkg}"

  q = quiet == true ? '> /dev/null' : ''
  builddir_pkg = Dir.glob(builddir/pkg/"#{pkg}*/").last

  if builddir_pkg
    log "Changing into detected extracted source directory #{builddir_pkg}"
    Dir.chdir builddir_pkg
  else
    log "Could not determine extracted source directory for #{pkg}"
    exit
  end

  if not buildcookie?(pkg)
    log "Running debuild for package #{pkg} with #{threads} threads"

    # Invoke debuild, save result in buildstatus
    buildstatus = shell %Q{DEB_BUILD_OPTIONS=nocheck debuild -us -uc -b -j#{threads} #{q}}

    if buildstatus == true
      log "Build succeeded for #{pkg}, setting build cookie."
      set_buildcookie(pkg)
    else
      log "Build for #{pkg} failed, not setting build cookie."
    end
  else
    log "Build cookie found for #{pkg}, skipping build."
  end
end

# Moves all *.deb files from the recipe directory to 'pkgdir' (default ./pkg)
# - pkg is the subdirectory to manage in 'pkgdir' to separate artefacts
#   between multiple builds executed with this helper. Automatically set
#   when executed after debian_get_source.
def debian_move(pkg: @pkg)
  # Move build output to pkgdir
  artefacts = Dir.glob(builddir/pkg/'*.deb')

  pkgdir(pkg).mkdir

  if artefacts.empty?
    log "No build artefacts found for #{pkg}"
    return
  else
    log "#{pkg} build artefacts: #{artefacts}"
    FileUtils.mv artefacts, pkgdir/pkg
    log "Moved build artefacts to #{pkgdir}"
  end
end

# Run apt-get install with a given package
# - pkg is the package to install
# - quiet silences apt-get output
def apt_install(pkg: nil, quiet: true)
  q = quiet == true ? '> /dev/null' : ''
  shell %Q{DEBIAN_FRONTEND=noninteractive apt-get install -y #{pkg.join(' ')} #{q}}
end

# Install a locally-generated artifact for use in a future local build
# - deb is the package (glob) to install to the system
def dpkg_install(pkg: @pkg, prefix: pkg, quiet: true)
  packages = Dir.glob(pkgdir/pkg/"#{prefix}*.deb")
  q = quiet == true ? '> /dev/null' : ''

  if packages.size > 0
    log "Found the following packages in #{pkgdir/pkg}: #{packages}."
    packages.each do |deb|
      log "Installing #{File.basename(deb)}"
      shell %Q{dpkg -i #{deb} #{q}}
    end
  else
    log "dpkg_install couldn't find any packages at " + pkgdir/pkg/"#{prefix}*.deb"
  end
end

# Cleans out 'builddir' (tmp_build/)
# - cache - when set to true, removes the cache directory too.
#   (This will lead debian_get_source to fetch sources again!)
def debian_cleanup(cache: false)
  # Clean up build and destdir
  %W|#{builddir} #{destdir}|.each do |dir|
    if Dir.exist?(dir)
      FileUtils.rm_rf(dir)
      log "Removed #{dir}"
    end
  end

  # Only delete cache if explicitly called
  if cache && Dir.exist?(cachedir)
    FileUtils.rm_rf(cachedir)
    log "Removed #{cachedir}"
  end
end

# Increment the Debian package version number by invoking 'dch -i' in builddir
# - reason sets the commit message prefixed by 'Bump <pkg>:' for 'dch'
# - pkg is the package to increment the version for. Automatically set by
#   running debian_get_source prior to this command in the same run.
#
# Sets a 'bumpcookie' in 'builddir'
def debian_bump_package(reason, pkg: @pkg)
  builddir_pkg = Dir.glob(builddir/pkg/"#{pkg}*/").last
  desc = "Bump #{pkg}: #{reason}"

  if not bumpcookie?(pkg)
    log "No bump cookie found for package #{pkg}, bumping"

    Dir.chdir builddir_pkg
    shell %Q{dch -i #{desc}}
    log "Successfully bumped Debian version of package #{pkg}"

    set_bumpcookie(pkg)
    log "Bump cookie set for package #{pkg}"
  end
end

#
# Cookies specifically for Debian package instructions
#
def bumpcookie?(pkg)
  File.exist?(builddir/".deb_bumpcookie_#{pkg}")
end

def set_bumpcookie(pkg)
  FileUtils.touch builddir/".deb_bumpcookie_#{pkg}"
end
