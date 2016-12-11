require '../../helpers/debian.rb'

class Php5Meta < FPM::Cookery::Recipe

  description 'server-side, HTML-embedded scripting language with pthreads'

  name    'php5-meta'
  section 'lanparty'
  version '1.0'

  homepage 'http://php.net'

  chain_package true
  chain_recipes 'php5'
  chain_recipes 'php5-json'

end
