require '../../helpers/debian.rb'

class Php5Json < FPM::Cookery::Recipe

  description 'This package provides a module for JSON functions in PHP scripts.'

  name    'php5-json'
  section 'lanparty'
  version '1.0'

  homepage 'http://php.net'

  # Use last-found (highest) folder matching the glob and copy it to build/
  source Dir.glob(cachedir/'php-json-*/').last, :with => 'directory'

  def build
    debian_build_dep name
    debian_get_source(pkg: name, tar_prefix: 'php-json')
    debuild 4
  end

  def install
    debian_move_deb
    debian_cleanup
  end

end
