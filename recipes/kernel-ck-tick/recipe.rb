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
    sh "patch -p1 -N -r- -i patch-#{version}-#{revision}"

    # Copy ticking kernel config
    FileUtils.cp datadir/"config-#{version}-#{revision}", sourcedir/".config"

    # Invoke kernel build
    sh 'make-kpkg clean'
    sh "make-kpkg --initrd --append-to-version -tick1k --revision=1.0 kernel_image kernel_headers -j4"
  end

  def install
    # Move output artifact to pkgdir (/pkg)
    FileUtils.mv Dir.glob(builddir/"linux-*-#{version}*.deb"), pkgdir
  end

end
