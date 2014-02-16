## The main manifest
import 'apt_setup.pp'
# include puppet_lint


## Install ansible
apt::ppa { 'ppa:rquillo/ansible': }
package {'ansible': ensure => '1.4.5-saucy-unstable1', } # Make sure we use a particular version


## Alternative: Use Ansible from saucy-backports
#apt::source {'saucy-backports':
#	location => 'http://archive.ubuntu.com/ubuntu',
#	release  => 'saucy-backports',
#	repos    => 'main restricted universe multiverse',
#}
#package {'ansible': ensure => '1.4.4+dfsg-1~ubuntu13.10.1', }

# Ansible needs sshpass when using passwords instead of keys for authentication; cowsay improves the fun factor
package {['sshpass', 'cowsay']: ensure => installed, }
