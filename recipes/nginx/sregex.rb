class Sregex < FPM::Cookery::Recipe
  description 'streaming regex library used in lanparty-nginx'

  name      'libsregex'
  provides  'libsregex'
  version   '0.0.1'
  revision  1
  section 'lanparty'

  homepage 'https://github.com/openresty/sregex'

  build_depends 'bison'

  default_prefix '/usr/local'

  post_install "scripts/#{name}-postinst"
  post_uninstall "scripts/#{name}-postinst"

  source 'https://github.com/openresty/sregex.git', :with => 'git', :branch => 'master'

  def build
    make
  end

  def install
    make :install, 'PREFIX' => prefix
  end

  def after_package_create(package)
    # This installs the resulting package to the container and solves
    # multiple problems:
    # - fpm-cookery wants to install libsregex before building,
    #   but the package is not available through APT
    # - Nginx dynamically links against this library in the next build step,
    #   so we install the correct version here
    # - This hook cleans up the `install` step above
    safesystem("dpkg -i /pkg/#{package}")
  end

end
