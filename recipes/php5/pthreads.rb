class Pthreads < FPM::Cookery::Recipe

  description 'pthreads module for php5-zts, git version'

  name     'php5-pthreads'
  section  'lanparty'
  version  '2.0.11' # This is the final pthreads version for php5
  revision '1'

  homepage 'https://github.com/krakjoe/pthreads'
  source 'https://github.com/krakjoe/pthreads', :with => 'git', :branch => 'PHP5'

  # ZTS-enabled php5-common should be installed before running,
  # since the `php-config` output will determine the build environment
  depends 'php5-common'

  config_files '/etc/php5/mods-available/pthreads.ini'

  # Manipulate pkgdir to separate build output from other recipes
  @pkgdir = pkgdir/name

  def php_extdir
    root(`php-config --extension-dir`.strip)
  end

  def after_source_download
    sh "git -C #{cachedir/'pthreads'} checkout PHP5"
    @gitref = `git -C #{cachedir/'pthreads'} rev-parse --short HEAD`.strip

    # Hack to inject revision into recipe after the source is downloaded
    @oldrev = revision
    def self.revision
      "#{@oldrev}+git~#{@gitref}"
    end
  end

  def build
    # Prepare build environment with phpize
    # (set PHP and Zend Module/Extension API versions)
    sh 'phpize'

    configure
    make '-j4'

    # Make sure our output object is not executable
    File.chmod(0644, 'modules/pthreads.so')
  end

  def install
    php_extdir.install 'modules/pthreads.so'
    etc('php5/mods-available').install workdir('config/pthreads.ini')
  end

end
