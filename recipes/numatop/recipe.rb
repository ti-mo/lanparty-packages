class NumaTop < FPM::Cookery::Recipe
  description 'CPU frequency and voltage scaling tools for Linux - common files'

  name      'numatop'
  version   '1.0.4'
  revision  1

  provides 'numatop'
  section 'lanparty'

  depends 'libnuma1', 'libncurses5', 'libtinfo5'
  build_depends 'libncurses5-dev', 'libnuma-dev'

  source "https://01.org/sites/default/files/numatop_linux_#{version}.tar.gz"
  sha256 '856324f9608667bc04c6edda6729e37ea21cc973455faeb6248ba38dc9bbd96b'

  @pkgdir = pkgdir/name

  def build
    make :install
  end

  def install
    # Stay consistent with Debian convention
    bin.install 'numatop'
    man8.install '/usr/share/man/man8/numatop.8.gz'
  end

end
