class KernelCkTick < FPM::Cookery::Recipe
  description 'Debian kernel with ck patchset and tick'

  name      'linux-image'
  version   '4.8'
  revision  'ck8'
  section   'lanparty'

  homepage 'https://kernel.org'

  build_depends \
    'fakeroot',
    'kernel-package',
    'libssl-dev'

  def before_dependency_installation
    if not File.file?(cachedir/"linux-source-#{version}.tar.xz")
      build_depends << "linux-source-#{version}"
    end
  end

  source "/usr/src/linux-source-#{version}.tar.xz", :with => 'local_path'

  def build
    # Get the CK patchset
    sh "wget -nc http://ck.kolivas.org/patches/4.0/#{version}/#{version}-#{revision}/patch-#{version}-#{revision}.xz"
    sh "unxz -kf patch-#{version}-#{revision}.xz"

    # Apply CK patchset to kernel tree
    patch "patch-#{version}-#{revision}", 1

    # Apply WireGuard patchset to kernel tree
    sh 'git clone https://git.zx2c4.com/WireGuard'
    sh "WireGuard/contrib/kernel-tree/create-patch.sh > wireguard-patch-#{version}-#{revision}"
    patch "wireguard-patch-#{version}-#{revision}", 1

    # Copy ticking kernel config
    FileUtils.cp datadir/"output/config-#{version}-#{revision}", sourcedir/".config"

    # Invoke kernel build
    sh 'make-kpkg clean'
    sh "make-kpkg --initrd --append-to-version -tick1k --revision=1.0 kernel_image kernel_headers -j4"
  end

  def install
    # Move output artifact to pkgdir (/pkg)
    FileUtils.mv Dir.glob(builddir/"linux-*-#{version}*.deb"), pkgdir
  end

end
