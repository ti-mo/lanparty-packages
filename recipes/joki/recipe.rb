class Joki < FPM::Cookery::Recipe
  description 'a lightweight latency tracker for InfluxDB'

  name      'joki'
  version   '0.1'
  revision  3

  homepage 'https://github.com/ti-mo/joki'

  provides 'joki'
  build_depends 'golang'
  depends 'fping'

  config_files '/etc/joki/config.toml.example'

  section 'lanparty'

  source 'http://git.incline.eu/timo/joki.git', :with => 'git', :branch => 'master'

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