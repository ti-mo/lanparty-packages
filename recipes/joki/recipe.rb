class Joki < FPM::Cookery::Recipe
  description 'a lightweight latency tracker for InfluxDB'

  name      'joki'
  version   '0.1'
  revision  3

  homepage 'https://github.com/ti-mo/joki'

  provides 'joki'
  section 'lanparty'

  build_depends 'golang'
  depends 'fping'

  config_files '/etc/joki/config.toml.example'

  # lib() reads (default_)prefix (/usr), but we want it in /lib instead
  default_prefix '/'

  source 'https://github.com/ti-mo/joki.git', :with => 'git', :branch => 'master'

  @pkgdir = pkgdir/name

  def build
    sh "go get"
    sh "go build -x -o joki"
  end

  def install
    etc('joki').install 'config.toml.example'

    bin.install 'joki'

    lib('systemd/system').install 'joki.service'
  end

end