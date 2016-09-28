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

  source "/usr/src/linux-source-#{version}.tar.xz", :with => 'local_path'

  def build
    # Get the CK patchset
    sh "wget http://ck.kolivas.org/patches/4.0/#{version}/#{version}-#{revision}/patch-#{version}-#{revision}.xz"
    sh "unxz -kf patch-#{version}-#{revision}.xz"
  end

  def install

  end

end
