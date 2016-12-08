require '../../helpers/debian.rb'

class Php5 < FPM::Cookery::Recipe

  description 'server-side, HTML-embedded scripting language with pthreads'

  name    'php5'
  section 'lanparty'
  version '1.0'

  homepage 'http://php.net'

  # Use last-found (highest) folder matching the glob and copy it to build/
  source Dir.glob(cachedir/'php5-*/').last, :with => 'directory'

  # Warning: apt-get build-dep for php5 needs a debian-stable installation
  # Installing many popular packages from backports will violate the build-deps
  def build
    debian_build_dep name
    debian_get_source(pkg: name)
    debuild 4
  end

  def install
    debian_move_deb
    debian_cleanup
  end

end
