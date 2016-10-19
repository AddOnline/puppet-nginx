# define: nginx::resource::location
#
# This definition creates a new location entry within a virtual host
#
# Parameters:
#   [*ensure*]               - Enables or disables the specified location (present|absent)
#   [*vhost*]                - Defines the default vHost for this location entry to include with
#   [*location*]             - Specifies the URI associated with this location entry
#   [*www_root*]             - Specifies the location on disk for files to be read from. Cannot be set in conjunction with $proxy
#   [*redirect*]             - Specifies a 301 redirection. You can either set proxy, www_root or redirect.
#                            The request_uri is automatically appended. Usage example: redirect => 'http://www.example.org'
#   [*index_files*]          - Default index files for NGINX to read when traversing a directory
#   [*proxy*]                - Proxy server(s) for a location to connect to. Accepts a single value, can be used in conjunction
#                            with nginx::resource::upstream
#   [*proxy_read_timeout*]   - Override the default the proxy read timeout value of 90 seconds
#   [*proxy_set_header*]     - Various Header Options
#   [*proxy_ssl_set_header*] - Various Header Options for SSL
#   [*fpm_server*]           - FPM server pass to fastcgi_pass
#   [*fpm_script_filename*]  - FPM SCRIPT_FILENAME. Default to $document_root$fastcgi_script_name
#   [*internal*]             - Set to true to add internal directive. Default: false
#   [*ssl*]                  - Indicates whether to setup SSL bindings for this location.
#   [*mixin_ssl*]            - Indicates whether SSL directive is to be put into the same file (only for backward compatibility)
#   [*limit_except*]         - Specifies that auth requests should be enclosed within a limit_except
#   [*auth_basic_user_file*] - auth_basic_user_file location
#   [*auth_basic*]           - auth_basic message
#   [*option*]               - Inject custom config items.
#   [*options*]              - Same as [*option*] but with an s for unification with nginx::resource::vhost.
#   [*order*]                - Contact default location order (Default: 50)
#   [*ssl_order*]            - Contact default ssl location order (Default: [*order*] + 30
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  nginx::resource::location { 'test2.local-bob':
#    ensure   => present,
#    www_root => '/var/www/bob',
#    location => '/bob',
#    vhost    => 'test2.local',
#  }
define nginx::resource::location(
  $ensure               = present,
  $vhost                = undef,
  $limit_except         = undef,
  $auth_basic_user_file = undef,
  $auth_basic           = undef,
  $www_root             = undef,
  $create_www_root      = false,
  $owner                = '',
  $groupowner           = '',
  $redirect             = undef,
  $index_files          = ['index.html', 'index.htm', 'index.php'],
  $proxy                = undef,
  $proxy_read_timeout   = '90',
  $proxy_set_header     = ['Host $host', 'X-Real-IP $remote_addr', 'X-Forwarded-For $proxy_add_x_forwarded_for', 'X-Forwarded-Proto $scheme' ],
  $proxy_ssl_set_header = [],
  $proxy_redirect       = undef,
  $fpm_server           = undef,
  $fpm_script_filename  = '$document_root$fastcgi_script_name',
  $internal             = false,
  $ssl                  = false,
  $ssl_only             = false,
  $option               = undef,
  $mixin_ssl            = undef,
  $template_ssl_proxy   = 'nginx/vhost/vhost_location_ssl_proxy.erb',
  $template_proxy       = 'nginx/vhost/vhost_location_proxy.erb',
  $template_directory   = 'nginx/vhost/vhost_location_directory.erb',
  $template_redirect    = 'nginx/vhost/vhost_location_redirect.erb',
  $template_fpm         = 'nginx/vhost/vhost_location_fpm.erb',
  $order                = '',
  $ssl_order            = '',
  $location             = $title
) {
  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => $nginx::manage_service_autorestart,
  }

  $bool_create_www_root = any2bool($create_www_root)
  $bool_ssl_only = any2bool($ssl_only)

  $manage_order = $order ? {
    ''      => 50,
    default => $order
  }
  $tmp_ssl_order = $manage_order + 30
  $manage_ssl_order = $ssl_order ? {
    ''      => $tmp_ssl_order,
    default => $ssl_order,
  }

  $real_owner = $owner ? {
    ''      => $nginx::config_file_owner,
    default => $owner,
  }

  $real_groupowner = $groupowner ? {
    ''      => $nginx::config_file_group,
    default => $groupowner,
  }

  ## Shared Variables
  $ensure_real = $ensure ? {
    'absent' => absent,
    default  => present,
  }

  $file_real = "${nginx::vdir}/${vhost}.conf"

  # Use proxy template if $proxy is defined, otherwise use directory template.
  if ($proxy != undef) {
    $content_real     = template($template_proxy)
    $content_ssl_real = template($template_ssl_proxy)
  } else {
    if ($redirect != undef) {
      $content_real = template($template_redirect)
      $content_ssl_real = template($template_redirect)
    } else {
      if ($fpm_server != undef) {
        $content_real     = template($template_fpm)
        $content_ssl_real = template($template_fpm)
      } else {
        $content_real     = template($template_directory)
        $content_ssl_real = template($template_directory)
      }
    }
  }

  ## Check for various error condtiions
  if ($vhost == undef) {
    fail('Cannot create a location reference without attaching to a virtual host')
  }
  if (($www_root == undef) and ($proxy == undef) and ($redirect == undef) and ($fpm_server == undef)) {
    fail('Cannot create a location reference without a www_root, proxy,fpm_server or redirect defined')
  }
  if (($www_root != undef) and ($proxy != undef)) {
    fail('Cannot define both directory and proxy in a virtual host')
  }
  if (($www_root != undef) and ($redirect != undef)) {
    fail('Cannot define both directory and redirect in a virtual host')
  }
  if (($www_root != undef) and ($fpm_server != undef)) {
    fail('Cannot define both directory and fpm_server in a virtual host')
  }
  if (($proxy != undef) and ($redirect != undef)) {
    fail('Cannot define both proxy and redirect in a virtual host')
  }
  if (($proxy != undef) and ($fpm_server != undef)) {
    fail('Cannot define both proxy and fpm_server in a virtual host')
  }
  if (($redirect != undef) and ($fpm_server != undef)) {
    fail('Cannot define both redirect and fpm_server in a virtual host')
  }
  if (($auth_basic_user_file != undef) and ($auth_basic == undef)) {
    fail('Cannot define auth_basic_user_file without auth_basic')
  }
  if (($auth_basic_user_file != undef) and ($auth_basic == undef)) {
    fail('Cannot define auth basic without a user file')
  }

  if $bool_create_www_root == true {
    file { $www_root:
      ensure => directory,
      owner  => $real_owner,
      group  => $real_groupowner,
    }
  }


  ## Create stubs for vHost File Fragment Pattern
  if $bool_ssl_only != true {
    concat::fragment { "${vhost}+50-${location}.tmp":
      ensure  => $ensure_real,
      order   => $manage_order,
      content => $content_real,
      target  => $file_real,
    }
  }

  if ($mixin_ssl) {
    ## Only create SSL Specific locations if $ssl is true.
    concat::fragment { "${vhost}+80-ssl-${location}.tmp":
      ensure  => $ssl,
      order   => $manage_ssl_order,
      content => $content_ssl_real,
      target  => $file_real,
    }
  }
}
