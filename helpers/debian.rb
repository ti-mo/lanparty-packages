Log = FPM::Cookery::Log

# Deletes all files ending in *.build and *.changes in the recipe directory
# Cleans out 'builddir' (tmp_build/)
def debian_cleanup
  # Remove build output ending in .build or .changes
  cleanup = Dir.glob(workdir/"*.{build,changes}")
  Log.info "Deleting the following files after successful build: #{cleanup}"
  FileUtils.rm(cleanup)

  # Clean up build directory
  if Dir.exist?(builddir)
    FileUtils.rm_rf(builddir/'*')
    Log.info "Cleared #{builddir}"
  end
end

# Download a source package to the cache folder
# - pkg is the package to download using 'apt-get source'
# - tar_prefix is the package to look for when conditionally downloading
#    It is used to generate a glob pattern: <tar_prefix>_*.orig.tar.xz
#    The default value is set to the value given to 'pkg'
def debian_get_source(pkg: nil, tar_prefix: pkg)
  if not pkg
    raise 'pkg parameter must be given to debian_get_source()'
  end

  pattern = "#{tar_prefix}_*.orig.tar.xz"
  tarball = Dir.glob(cachedir/pattern).last

  if not Dir.exist?(cachedir)
    mkdir cachedir
  end

  if not tarball
    Log.info 'No glob matches found for ' + cachedir/pattern

    # run apt-get source in cache/
    chdir cachedir
    sh "apt-get source #{pkg}"
  else
    Log.info "Found source archive at #{tarball}, skipping apt-get source"
  end
end

# Moves all *.deb files from the recipe directory to 'pkgdir' (default ./pkg)
def debian_move_deb
  # Move build output to pkgdir
  output = Dir.glob(workdir/'*.deb')

  if output.empty?
    Log.error "No build output found for #{name}, continuing"
  else
    Log.info "#{name} build output: #{output}"
    FileUtils.mv output, pkgdir
    Log.info "Moved build output to #{pkgdir}"
  end
end

# Executes debuild with the specified number of threads
def debuild(threads = 4)
  if not threads.to_s =~ /^[0-9]+$/
    raise 'amount of threads given to debuild() needs to be an integer'
  end

  sh "DEB_BUILD_OPTIONS=nocheck debuild -us -uc -b -j#{threads} > /dev/null"
end
