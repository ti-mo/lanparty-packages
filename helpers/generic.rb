require 'pathname'

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

def workdir(dir = nil)
  dir.gsub!(%r{^/}, '') if dir

  # Store the workdir when this method is called for the first time
  (@workdir ||= Path.pwd)/dir
end

def pkgdir(path = nil)
  workdir('pkg')/path
end

def cachedir(path = nil)
  workdir('cache')/path
end

def builddir(path = nil)
  workdir('tmp-build')/path
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
