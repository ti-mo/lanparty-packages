class Sregex < FPM::Cookery::Recipe
  description 'streaming regex library used in lanparty-nginx'

  name      'libsregex'
  provides  'libsregex'
  version   '0.1'
  revision  1

  homepage 'https://github.com/openresty/sregex'

  build_depends 'bison'

  default_prefix '/usr/local'

  section 'lanparty'

  source 'https://github.com/openresty/sregex.git', :with => 'git', :branch => 'master'

  def build
    make
  end

  def install
    make :install, 'PREFIX' => prefix

    # This installs the library onto the container/system for use during Nginx build
    make :install, 'DESTDIR' => '/', 'PREFIX' => default_prefix
  end

end
