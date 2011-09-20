define vhost (
	$ensure = "present",
	$ip = "*",
	$port = "80",
	$serveradmin = "root@localhost",
	$servername = 'localhost',
	$documentroot = "$vhosts::root/$servername/htdocs",
	$createroot = 'yes',
	$serveralias,
	$baselogdir = $::operatingsystem ? {
		default => '/var/log/httpd',
		/debian|ubuntu/ => '/var/log/apache2',
	},
	$apacheuser = $::operatingsystem ? {
		default => 'apache',
		/debian|ubuntu/ => 'root',
	},
	$apachegroup = $::operatingsystem ? {
		default => 'apache',
		/debian|ubuntu/ => 'root',
	}
) {
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
			recurse => true,
			require => File["$vhosts::root"];
	}

#	create config files
	file {
		"/etc/httpd/conf.d/$servername.conf":
			ensure => $ensure,
			name => $::operatingsystem ? {
				/debian|ubuntu/ => "/etc/apache2/sites-available/$servername.conf",
				/CentOS|fedora/ => "/etc/httpd/conf.d/$servername.conf",
			},
			mode    => 0644,
#			notify => Service["httpd"],
			content => template("vhost/vhost.conf.erb");
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
}
