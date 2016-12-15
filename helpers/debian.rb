require_relative 'generic.rb'

# Download a source package to the cache folder
# - pkg is the package to download using 'apt-get source'
# - tar_prefix is the package to look for when conditionally downloading
#    It is used to generate a glob pattern: <tar_prefix>_*.orig.tar.xz
#    The default value is set to the value given to 'pkg'
def debian_get_source(pkg: nil, tar_prefix: pkg, quiet: true)
  if not pkg
    raise 'pkg parameter must be given to debian_get_source()'
  end

  # Assign root instance variable to pass pkg between other methods
  @pkg ||= pkg

  pattern = "#{tar_prefix}_*.orig.tar.xz"
  tarball = Dir.glob(cachedir/pkg/pattern).last
  q = quiet ? '> /dev/null' : ''

  # Ensure cachedir exists
  cachedir(pkg).mkdir

  if not tarball
    log 'No glob matches found for ' + cachedir/pkg/pattern

    # run apt-get source in cache/
    chdir cachedir/pkg
    log "Running 'apt-get source' for package #{pkg}"
    shell %Q{apt-get source #{pkg} #{q}}
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
end

# Executes debuild with the specified number of threads
def debuild(threads: 4, quiet: true, pkg: @pkg)
  if not threads.to_s =~ /^[0-9]+$/
    raise 'amount of threads given to debuild() needs to be an integer'
  end

  if not pkg
    raise 'pkg attribute not given, nor could it be inferred from context'
  end

  q = quiet == true ? '> /dev/null' : ''
  builddir_pkg = Dir.glob(builddir/pkg/"#{pkg}*/").last

  if builddir_pkg
    log "Changing into detected extracted source directory #{builddir_pkg}"
    chdir builddir_pkg
  else
    log "Could not determine extracted source directory"
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
def debian_move_deb
  # Move build output to pkgdir
  output = Dir.glob(workdir/'*.deb')

  if output.empty?
    Log.error "No build output found for #{name}, continuing"
  else
    log "#{name} build output: #{output}"
    FileUtils.mv output, pkgdir
    log "Moved build output to #{pkgdir}"
  end
end

# Deletes all files ending in *.build and *.changes in the recipe directory
# Cleans out 'builddir' (tmp_build/)
def debian_cleanup
  # Remove build output ending in .build or .changes
  cleanup = Dir.glob(workdir/"*.{build,changes}")
  log("Deleting the following files after successful build: #{cleanup}")
  FileUtils.rm(cleanup)

  # Clean up build directory
  if Dir.exist?(builddir)
    FileUtils.rm_rf(builddir/'*')
    log "Cleared #{builddir}"
  end
end

def bumpcookie?(pkg)
  File.exist?(builddir/".deb_bumpcookie_#{pkg}")
end

def set_bumpcookie(pkg)
  FileUtils.touch builddir/".deb_bumpcookie_#{pkg}"
end
