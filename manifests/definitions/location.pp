define vhost::location (
	$path,
	$vhost,
	$webdav = 'no',
	$auth = 'no',
	$exists = 'no',
	$user = 'webdav',
	$pass = 'webdav',
	$ldap = 'no',
	$ldap_url = '',
	$ldap_dn = '',
	$ldap_pass = '',
	$allow_users = 'all'
) {
#	default exec path
	Exec {
		path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin'
	}

#	config file
	file {
		"/etc/httpd/conf.d/$vhost.locations/$name.conf":
			ensure => present,
			mode => 0644,
#			notify => Service['httpd'],
			content => template('vhosts/vhost.location.erb');
	}

#	docroot
	if $exists == 'no' {
		file {
			"$path":
				ensure => 'directory',
				owner => "$apache::user",
				group => "$apache::group",
				mode => '0755';
		}
	}

#	auth stuff
	if $auth == 'yes' {
		file {
			"$path/.htpasswd":
				ensure => "present",
				owner => "$apache::user",
				group => "$apache::group",
				require => File["$path"];
		}

		exec {
			"htpasswd_webdav_$servername":
				command => "htpasswd -mb $path/.htpasswd $user $pass", 
				unless => "grep $pass $path/.htpasswd",
				require => File["$path/.htpasswd"];
		}
	}
}
