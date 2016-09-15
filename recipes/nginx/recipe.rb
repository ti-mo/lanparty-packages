class Nginx < FPM::Cookery::Recipe
  description 'high-performance web server built with replace-filter module'

  name      'nginx'
  version   '1.11.4'
  revision  1
  provides  'nginx'
  section   'lanparty'

  homepage 'https://nginx.org'

  build_depends 'libpcre3-dev', 'zlib1g-dev', 'libssl-dev'

  # Contains default config file, systemd unit, etc.
  depends 'nginx-common'

  exclude 'etc'

  source "https://nginx.org/download/nginx-#{version}.tar.gz"
  sha256 '06221c1f43f643bc6bfe5b2c26d19e09f2588d5cde6c65bdb77dfcce7c026b3b'

  def build
    safesystem('git clone https://github.com/openresty/replace-filter-nginx-module.git')

    configure \
      '--with-http_ssl_module',
      '--with-http_realip_module',
      '--with-http_addition_module',
      '--with-http_sub_module',
      '--with-http_dav_module',
      '--with-http_flv_module',
      '--with-http_mp4_module',
      '--with-http_gunzip_module',
      '--with-http_gzip_static_module',
      '--with-http_random_index_module',
      '--with-http_secure_link_module',
      '--with-http_stub_status_module',
      '--with-http_auth_request_module',
      '--with-mail',
      '--with-mail_ssl_module',
      '--with-file-aio',
      '--with-ipv6',
      '--with-threads',
      '--with-stream',
      '--with-stream_ssl_module',
      '--with-http_slice_module',
      '--with-http_v2_module',

      '--add-module=replace-filter-nginx-module',

      :sbin_path => '/usr/sbin/nginx',
      :conf_path => '/etc/nginx/nginx.conf',
      :lock_path => '/var/lock/nginx.lock',
      :pid_path => '/run/nginx.pid',
      :http_log_path => '/var/log/nginx/access.log',
      :error_log_path => '/var/log/nginx/error.log',
      :http_client_body_temp_path => '/var/lib/nginx/body',
      :http_fastcgi_temp_path => '/var/lib/nginx/fastcgi',
      :http_proxy_temp_path => '/var/lib/nginx/proxy',
      :http_scgi_temp_path => '/var/lib/nginx/scgi',
      :http_uwsgi_temp_path => '/var/lib/nginx/uwsgi'

    make
  end

  def install
    make :install, 'DESTDIR' => destdir

    # Holds cache files etc., not created by make
    var('lib/nginx').mkpath

  end

  chain_package true
  chain_recipes 'sregex'

end
