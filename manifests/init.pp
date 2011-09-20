import 'definitions/*'

class vhosts (
	$root = "/var/vhosts"
) {
	file {
		"$vhosts::root":
		owner => root,
		group => root,
		mode => 755,
		ensure => directory;
	}
}
