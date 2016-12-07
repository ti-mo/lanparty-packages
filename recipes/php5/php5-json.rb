class Php5Json < FPM::Cookery::Recipe

  Log = FPM::Cookery::Log

  description 'server-side, HTML-embedded scripting language with pthreads'

  name    'php5-json'
  section 'lanparty'
  version nil

  homepage 'http://php.net'

  build_depends \
    'php5-dev',
    'dh-php5',
    'libjson-c-dev'

  source Dir.glob(cachedir/'php-json-*/').last, :with => 'directory'

  # Conditionally download the source package if it's missing
  def before_dependency_installation

    pattern = 'php-json_*.orig.tar.xz'
    tarball = Dir.glob(cachedir/pattern).last

    if not Dir.exist?(cachedir)
      mkdir cachedir
    end

    if not tarball
      Log.info 'No glob matches found for ' + cachedir/pattern

      # run apt-get source
      chdir cachedir
      sh "apt-get source php5-json"

    else
      Log.info "Found source archive at #{tarball}, skipping apt-get source"
    end

  end

  def build
    sh "DEB_BUILD_OPTIONS=nocheck debuild -us -uc -b -j6"
  end

  def install
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

  def after_install()
    # Remove build output ending in .build or .changes
    %w|changes build|.each { |i|
      cleanup = Dir.glob(workdir/"php-json_*.#{i}")
      Log.warn cleanup
      FileUtils.rm(cleanup)
    }

    # Clean up build directory
    if Dir.exist?(builddir)
      FileUtils.rm_rf(builddir)
    end
  end
end
