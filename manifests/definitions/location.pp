define vhost::location (
	$location,
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
		"/etc/httpd/conf.d/$servername.locations/$location.conf":
			ensure => present,
			mode => 0644,
#			notify => Service['httpd'],
			content => template('vhosts/vhost.location.erb');
	}

#	docroot
	if $exists == 'no' {
		file {
			"$location":
				ensure => 'directory',
				owner => "$apache::user",
				group => "$apache::group",
				mode => '0755';
		}
	}

#	auth stuff
	if $auth == 'yes' {
		file {
			"$location/.htpasswd":
				ensure => "present",
				owner => "$apache::user",
				group => "$apache::group",
				require => File["$location"];
		}

		exec {
			"htpasswd_webdav_$servername":
				command => "htpasswd -mb $location/.htpasswd $user $pass", 
				unless => "grep $pass $location/.htpasswd",
				require => File["$location/.htpasswd"];
		}
	}
}
