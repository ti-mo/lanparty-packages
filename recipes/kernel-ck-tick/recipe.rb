class KernelCkTick < FPM::Cookery::Recipe
  description 'Debian kernel with ck patchset and tick'

  name      'linux-image'
  version   '4.6'
  revision  'ck1'
  section   'lanparty'

  homepage 'https://kernel.org'

  build_depends \
    'fakeroot',
    'kernel-package',
    "linux-source-#{version}"

  source "http://ck.kolivas.org/patches/4.0/#{version}/#{version}-#{revision}/patch-#{version}-#{revision}.xz"
  sha256 '4475edebbcac102e5d92921970c12b22482c08069cc1478a7c922453611e0871'

  def build

  end

  def install

  end

end
