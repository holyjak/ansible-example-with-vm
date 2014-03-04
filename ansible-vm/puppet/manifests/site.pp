## The main manifest
import 'apt_setup.pp'
# include puppet_lint


## Install ansible
# NOTE: The Apt module works badly and fails to install a. from ppa upon first run, 2nd is ok
#apt::ppa { 'ppa:rquillo/ansible': } ->
#exec {'make ansible visible': command => '/usr/bin/apt-get update', } -> # The Apt module should do this for us :-(
#package {'ansible': ensure => '1.4.5-saucy-unstable1', } # Make sure we use a particular version


## Alternative: Use Ansible from saucy-backports
apt::source {'saucy-backports':
	location => 'http://archive.ubuntu.com/ubuntu',
	release  => 'saucy-backports',
	repos    => 'main restricted universe multiverse',
  before   => Exec['make ansible visible'],
}
exec {'make ansible visible': command => '/usr/bin/apt-get update', before => Package['ansible'], }
package {'ansible': ensure => '1.4.4+dfsg-1~ubuntu13.10.1', }

## Tip: replace the above with the following, after downloading https://forge.puppetlabs.com/ithempel/ppa 1.0.2
#ppa::repo { 'rquillo/ansible': supported  => ['saucy'], } ->
#package {'ansible': ensure => '1.5-saucy-unstable1', }

# Ansible needs sshpass when using passwords instead of keys for authentication; cowsay improves the fun factor
package {['sshpass', 'cowsay']: ensure => installed, }
