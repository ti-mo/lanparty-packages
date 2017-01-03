class Consul < FPM::Cookery::Recipe
  description 'A distributed service discovery tool'

  name      'consul'
  version   '0.7.2'
  revision  1

  homepage 'https://consul.io'

  provides 'consul'
  section  'lanparty'

  depends 'monitoring-plugins-basic'

  # lib() reads (default_)prefix (/usr), but we want it in /lib instead
  default_prefix '/usr/local'

  source "https://releases.hashicorp.com/consul/#{version}/consul_#{version}_linux_amd64.zip"
  sha256 'aa97f4e5a552d986b2a36d48fdc3a4a909463e7de5f726f3c5a89b8a1be74a58'

  def build
  end

  def install
    # Make Consul config directories
    %w(services checks).each { |d| mkpath etc("consul.d/#{d}") }

    # Install Consul binary
    bin.install 'consul'
  end

end