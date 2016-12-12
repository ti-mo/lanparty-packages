
cachedir = 'cache'
tmpdir = 'tmp-build'
pkgdir = 'pkg'

def /(path)
  self + (path || '').to_s.gsub(%r{^/}, '')
end

def log(text)
	puts "--> #{text}"
end
