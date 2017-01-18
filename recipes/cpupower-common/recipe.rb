class CpuPowerCommon < FPM::Cookery::Recipe
  description 'CPU frequency and voltage scaling tools for Linux - common files'

  name      'cpupower-common'
  version   '0.1'
  revision  1

  provides 'cpupower-common'
  section 'lanparty'

  depends 'linux-cpupower'

  config_files '/etc/default/cpupower'

  source 'local', :with => 'noop'

  # lib() reads (default_)prefix (/usr), but we want it in /lib instead
  default_prefix '/'

  @pkgdir = pkgdir/name

  def build
  end

  def install
    etc('default').install workdir('cpupower.default'), 'cpupower'
    lib('systemd/system').install workdir('cpupower.service')
    lib('systemd/scripts').install workdir('cpupower.script'), 'cpupower'
  end

end