class NginxMeta < FPM::Cookery::Recipe
  name    'nginx-meta'
  version '1.0'

  chain_package true
  chain_recipes 'sregex'
  chain_recipes 'nginx'
end
