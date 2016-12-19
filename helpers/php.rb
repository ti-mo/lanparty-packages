require_relative 'generic.rb'

def php_inject_zts
  pkg = @pkg

  builddir_pkg = Dir.glob(builddir/pkg/"#{pkg}*/").last
  rulesfile = builddir_pkg+'debian/rules'

  if File.readlines(rulesfile).grep(/enable-maintainer-zts/).size > 0
    log "ZTS flag found in debian/rules, skipping."
  else
    log "No ZTS flag found, injecting into #{rulesfile}"

    newrules = File.read(rulesfile).gsub(/^(COMMON_CONFIG=.*\n)/, "\\1--enable-maintainer-zts \\\n")
    File.open(rulesfile, 'w') { |file| file.write(newrules) }
  end
end
