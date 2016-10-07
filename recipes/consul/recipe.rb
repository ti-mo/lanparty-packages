class Consul < FPM::Cookery::Recipe
  description 'A distributed service discovery tool'

  name      'consul'
  version   '0.7.0'
  revision  1

  homepage 'https://consul.io'

  provides 'consul'
  section  'lanparty'

  depends 'monitoring-plugins-basic'

  # lib() reads (default_)prefix (/usr), but we want it in /lib instead
  default_prefix '/usr/local'

  source "https://releases.hashicorp.com/consul/#{version}/consul_#{version}_linux_amd64.zip"
  sha256 'b350591af10d7d23514ebaa0565638539900cdb3aaa048f077217c4c46653dd8'

  def build
  end

  def install
    # Make Consul config directories
    %w(services checks).each { |d| mkpath etc("consul.d/#{d}") }

    # Install Consul binary
    bin.install 'consul'
  end

end