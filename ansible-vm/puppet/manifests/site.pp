## The main manifest
import 'apt_setup.pp'
# include puppet_lint

apt::source {'saucy-backports':
	location => 'http://archive.ubuntu.com/ubuntu',
	release  => 'saucy-backports',
	repos    => 'main restricted universe multiverse',
}
package {'ansible': ensure => '1.4.4+dfsg-1~ubuntu13.10.1', }
package {['sshpass', 'cowsay']: ensure => installed, }
