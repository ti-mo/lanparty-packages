class Nginx < FPM::Cookery::Recipe
  description 'high-performance web server built with replace-filter module'

  name      'nginx'
  version   '1.11.4'
  revision  1
  provides  'nginx'

  homepage 'https://nginx.org'

  build_depends 'nginx'

  config_files '/etc'
  default_prefix '/'

  section 'lanparty'

  source 'https://nginx.org/download/nginx-${version}.tar.gz'

  def build
    configure '--sbin-path=/usr/sbin/nginx',
              '--conf-path=/etc/nginx/nginx.conf',
              '--error-log-path=/var/log/nginx/error.log',
              '--http-log-path=/var/log/nginx/access.log',
              '--http-client-body-temp-path=/var/lib/nginx/body',
              '--http-fastcgi-temp-path=/var/lib/nginx/fastcgi',
              '--http-proxy-temp-path=/var/lib/nginx/proxy',
              '--http-scgi-temp-path=/var/lib/nginx/scgi',
              '--http-uwsgi-temp-path=/var/lib/nginx/uwsgi',
              '--lock-path=/var/lock/nginx.lock',
              '--pid-path=/run/nginx.pid',
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
              '--add-module=../replace-filter-nginx-module'
    make
  end

  def install
    make :install
  end

end