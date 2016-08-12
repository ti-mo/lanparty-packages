class Joki < FPM::Cookery::Recipe
  description 'lightweight SmokePing alternative for InfluxDB'

  name      'joki'
  version   '0.1'
  revision  3

  homepage 'https://github.com/ti-mo/joki'

  build_depends 'golang'
  depends 'fping'

  provides 'joki'

  source 'http://git.incline.eu/timo/joki.git', :with => 'git', :branch => 'master'

  def build
    sh "go get"
  end

  def install
    make :install, 'DESTDIR' => destdir
  end

end