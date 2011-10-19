define vhost (
	$ensure = "present",
	$ip = "*",
	$port = "80",
	$serveradmin = "root@localhost",
	$servername = "localhost",
	$documentroot = "$vhosts::root/$servername/htdocs",
	$createroot = 'yes',
	$serveralias,
	$baselogdir = $::operatingsystem ? {
		default => '/var/log/httpd',
		/debian|ubuntu/ => '/var/log/apache2',
	},
	$apacheuser = $::operatingsystem ? {
		default => 'apache',
		archlinux => 'http',
		/debian|ubuntu/ => 'root',
	},
	$apachegroup = $::operatingsystem ? {
		default => 'apache',
		archlinux => 'http',
		/debian|ubuntu/ => 'root',
	},
	$webdav = '',
	$webdav_auth = 'yes',
	$webdav_user = 'webdav',
	$webdav_pass = 'webdav',
	$ssl = 'off',
	$sslport = '443',
	$ssl_certfile = '/etc/pki/tls/certs/ca.crt',
	$ssl_keyfile = '/etc/pki/tls/private/ca.key',
	$proxy = 'no',
	$proxypath = '/',
	$proxytarget = nil,
	$proxyrequests = 'off',
	$insecure = 'yes',
	$prior = ''
) {
#	define default path for exec resources
	Exec {
		path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin'
	}

#	create logdir/logs
	file {
		"$baselogdir/$servername/":
			ensure => $ensure ? {
				present => 'directory',
				absent => 'absent',
			},
			owner => $apacheuser,
			group => $apachegroup,
			recurse => true,
			purge => true,
			force => true;
		"$baselogdir/$servername/access.log":
			ensure => $ensure,
			group => $apachegroup,
			owner => $apacheuser;
		"$baselogdir/$servername/error.log":
			ensure => $ensure,
			group => $apachegroup,
			owner => $apacheuser;
	}

#	create root if necessary
   	if $createroot =='yes' {
		exec{
			"/bin/mkdir -p $documentroot":
  				unless => "/usr/bin/test -d $documentroot",
				before => File["$documentroot"];
		}
	}

#	ensure the documentroot is present
	file {
		"$documentroot":
			ensure => $ensure ? {
				present => 'directory',
				absent =>  'absent',
			},
			owner => $apacheuser,
			group => $apachegroup,
			purge => true,
			force => true,
			require => File["$vhosts::root"];
	}

#	create config files
	file {
		"/etc/httpd/conf.d/$servername.conf":
			ensure => $ensure,
			name => $prior ? {
				default => $::operatingsystem ? {
					default => "/etc/httpd/conf.d/$prior-$servername.conf",
					/debian|ubuntu/ => "/etc/apache2/sites-available/$prior-$servername.conf",
				},

				'' => $::operatingsystem ? {
					default => "/etc/httpd/conf.d/$servername.conf",
					/debian|ubuntu/ => "/etc/apache2/sites-available/$servername.conf",
				},
			},
			mode    => 0644,
#			notify => Service["httpd"],
			content => template("vhosts/vhost.conf.erb");
	}
			
#	if on debian based systems link config
	if $::operatingsystem in ['debian', 'ubuntu'] {
		file {"000-$servername":
			name => "/etc/apache2/sites-enabled/000-$servername",
			target => "/etc/apache2/sites-available/$servername",
			ensure =>  $ensure ? {
				present => 'link',
				absent => 'absent',
			};
		}
	}

#	webdav stuff
	if $webdav {
		file {
			"$documentroot/.htpasswd":
				ensure => "$ensure",
				owner => "$apacheuser",
				group => "$apachegroup";
		}

		exec {
			"htpasswd_$servername":
				command => "htpasswd -mb $documentroot/.htpasswd $webdav_user $webdav_pass", 
				unless => "grep $webdav_pass $documentroot/.htpasswd",
				require => File["$documentroot/.htpasswd"];
		}
	}

#	ssl stuff
	if $ssl {
		file {
			"cert_answers_$name":
				path => "/etc/pki/tls/private/cert_answers_$name",
				content => template('vhosts/cert_answers.erb');
		}

		exec {
			"gen_ssl_cert_$name":
				command => "openssl genrsa -out $ssl_keyfile 1024",
				unless => "test -f $ssl_keyfile";

			"create_cert_request_$name":
				command => "openssl req -new -key $ssl_keyfile -out ca.csr<cert_answers_$name",
#				cwd => "`dirname $ssl_certfile`",
				cwd => '/etc/pki/tls/private',
				unless => "test -f `dirname $ssl_certfile`/ca.csr",
				require => [ Exec["gen_ssl_cert_$name"], File["cert_answers_$name"]  ];

			"sign_cert_$name":
				command => "openssl x509 -req -days 3650 -in ca.csr -signkey $ssl_keyfile -out $ssl_certfile",
				cwd => '/etc/pki/tls/private',
				unless => "test -f $ssl_certfile",
				require => Exec["create_cert_request_$name"];
		}
	}
}
