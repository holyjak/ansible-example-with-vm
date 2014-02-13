# Install puppet-lint
# To run it:
#    puppet-lint --with-filename /path/to/manifests
#    (in vagrant: puppet-lint --with-filename /vagrant/puppet/)
class puppet_lint {
  package { 'rubygems': ensure => installed, }

  # See http://www.puppetcookbook.com/posts/install-rubygem.html
  package { 'puppet-lint':
    ensure => installed,
    provider => 'gem',
    require => Package['rubygems'],
  }
}
