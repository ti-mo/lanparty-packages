class OhMyZsh < FPM::Cookery::Recipe
  description 'Oh My Zsh is a way of life!'

  name      'oh-my-zsh'
  arch      'all'
  version   '1.0'
  revision  1

  homepage 'https://github.com/robbyrussell/oh-my-zsh'

  section 'lanparty'

  depends  'zsh', 'zsh-common'

  post_install 'post-install'
  post_uninstall 'post-uninstall'

  source 'https://github.com/robbyrussell/oh-my-zsh.git', :with => 'git', :branch => 'master'

  @pkgdir = pkgdir/name

  def after_source_download
    sh "git -C #{cachedir/'oh-my-zsh.git'} checkout master"
    @gitref = `git -C #{cachedir/'oh-my-zsh.git'} rev-parse --short HEAD`.strip

    # Hack to inject revision into recipe after the source is downloaded
    @oldrev = revision

    def self.revision
      "#{@oldrev}+master~#{@gitref}"
    end
  end

  def build
  end

  def install
    share('oh-my-zsh').install Dir[builddir/'oh-my-zsh-branch-master/*']

    share('oh-my-zsh/templates').install workdir('config/zshrc')
  end

end
