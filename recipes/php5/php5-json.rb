require '../../helpers/debian.rb'

class Php5Json < FPM::Cookery::Recipe

  description 'server-side, HTML-embedded scripting language with pthreads'

  name    'php5-json'
  section 'lanparty'
  version nil

  homepage 'http://php.net'

  build_depends \
    'php5-dev',
    'dh-php5',
    'libjson-c-dev'

  # Use last-found (highest) folder matching the glob and copy it to build/
  source Dir.glob(cachedir/'php-json-*/').last, :with => 'directory'

  # Hook Implementations
  def before_dependency_installation
    debian_get_source(pkg: 'php5-json', tar_prefix: 'php-json')
  end

  def build
    debuild 4
  end

  def install
    debian_move_deb
  end

  def after_install
    debian_cleanup
  end
end
