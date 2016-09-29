class KernelCkTick < FPM::Cookery::Recipe
  description 'Debian kernel with ck patchset and tick'

  name      'linux-image'
  version   '4.7'
  revision  'ck5'
  section   'lanparty'

  homepage 'https://kernel.org'

  build_depends \
    'fakeroot',
    'kernel-package',
    "linux-source-#{version}"

  source "/usr/src/linux-source-#{version}.tar.xz", :with => 'local_path'

  def build
    # Get the CK patchset
    sh "wget -nc http://ck.kolivas.org/patches/4.0/#{version}/#{version}-#{revision}/patch-#{version}-#{revision}.xz"
    sh "unxz -kf patch-#{version}-#{revision}.xz"

    # Apply CK patchset to kernel tree
    sh "patch -p1 -N -r- -i patch-#{version}-#{revision}"

    # Copy ticking kernel config
    FileUtils.cp datadir/"config-#{version}-#{revision}", sourcedir/".config"
  end

  def install

  end

end
