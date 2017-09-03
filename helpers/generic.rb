require 'pathname'

#
# Path class that shapes a DSL that allows other methods and the Rakefile to
# intuitively specify tokens like `builddir/'php'`, easy to read.
#
# Provides an idempotent mkdir call.
#
class Path < Pathname
  if '1.9' <= RUBY_VERSION
    alias_method :to_str, :to_s
  end

  def self.pwd(path = nil)
    new(Dir.pwd)/path
  end

  def /(path)
    self + (path || '').to_s.gsub(%r{^/}, '')
  end

  def +(other)
    other = Path.new(other) unless Path === other
    Path.new(plus(@path, other.to_s))
  end

  def mkdir
    if not Dir.exist?(self.to_s)
      # FileUtils.mkdir_p in Ruby 1.8.7 does not return an array.
      Array(FileUtils.mkdir_p(self.to_s))
    end
  end
end

#
# Directory helpers and configuration
#
def newpath(dir)
  dir.is_a?(Path) ? dir : Path.new(dir)
end

def workdir(dir = nil)
  # Ignore leading slash in dir param to prevent 'breakout' above workdir
  dir.gsub!(%r{^/}, '') if dir

  # Store the workdir when this method is called for the first time
  (@workdir ||= Path.pwd)/dir
end

def pkgdir(path = nil)
  (@pkgdir ||= workdir('pkg'))/path
end

def cachedir(path = nil)
  (@cachedir ||= workdir('cache'))/path
end

def builddir(path = nil)
  (@builddir ||= workdir('tmp-build'))/path
end

def destdir(path = nil)
  (@destdir ||= workdir('tmp-dest'))/path
end

#
# Cookies
# Om nom
#
def extractcookie?(pkg)
  File.exist?(builddir/".extractcookie_#{pkg}")
end

def set_extractcookie(pkg)
  FileUtils.touch builddir/".extractcookie_#{pkg}"
end

def buildcookie?(pkg)
  File.exist?(builddir/".buildcookie_#{pkg}")
end

def set_buildcookie(pkg)
  FileUtils.touch builddir/".buildcookie_#{pkg}"
end

def log(text)
	puts "--> #{text}"
end

# From fpm. (lib/fpm/util.rb)
def shell(*args)
  # Make sure to avoid nil elements in args. This might happen on 1.8.
  success = system(*args.compact.flatten)
  if !success
    raise "'system(#{args.inspect})' failed with error code: #{$?.exitstatus}"
  end
  return success
end

# Copy the pkg's cache directory to the temporary build directory.
# Returns the last alphabetical directory in the build directory.
#
# - pkg (default @pkg) is the package name to search for in cachedir
def extract_cache(pkg: @pkg)
  # Ensure builddir exists
  builddir(pkg).mkdir

  if not extractcookie?(pkg)
    log "No extract cookie found for package #{pkg}, copying to " + builddir/pkg

    # Copy source tree from cache to builddir
    FileUtils.cp_r "#{cachedir/pkg}/.", builddir/pkg

    set_extractcookie(pkg)
  else
    log "Extract cookie found at " + builddir/".extractcookie_#{pkg}" + ", skipping"
  end

  # Best effort to guess extracted source directory
  return newpath(Dir.glob(builddir(pkg)/'*/').last)
end

# Pull a git repository and return its location on disk,
# using cachedir/reponame-git as a convention.
# Additionally uses the @pkg variable to nest/group its download
#
# - url is the git url
# - branch (default 'master') is the branch to check out
# - quiet (default true) squelches stderr/stdout
# - extract (default false) copies the git directory to the build cache
def git(url: nil, branch: 'master', quiet: true, extract: false)
  if not url
    raise "url not given in git call"
  end

  q = quiet ? '> /dev/null 2>&1' : ''
  gitname = "#{url.split('/').last.split('.').first}-git"
  gitcachedir = @pkg ? cachedir/@pkg/gitname : cachedir/gitname

  if not Dir.exist?(gitcachedir)
    # Clone repo if dir does not exist
    log "Cloning repo #{gitname} into #{gitcachedir}"
    shell %Q{git clone #{url} #{gitcachedir} #{q}}
  end

  Dir.chdir(gitcachedir) {
    # Check out branch specified in branch argument
    log "Checking out branch '#{branch}' in repo '#{gitname}'"
    shell %Q{git checkout #{branch} #{q}}

    # Pull the branch
    log "Pulling branch '#{branch}'"
    shell %Q{git pull #{q}}
  }

  if extract
    return extract_cache
  end

  return gitcachedir
end
