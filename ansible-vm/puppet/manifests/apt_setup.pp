# APT setup: 
# - run apt update
# - add ppt repos
# - support localy stored archives
class apt_setup {

  class {'apt': } # from puppetlabs/apt module - f.ex. support for apt::ppa {'pkg':}

  $local_repo='/vagrant/offline/apt-archives'

  # Create an empty "local apt repo" if it doesn't exist so
  # that apt-get update won't complain
  file {['/vagrant/offline', $local_repo]:
    ensure => directory,
  }
  file { "${local_repo}/Packages":
    ensure => file,
  }

  # Enable unsigned packages from the local repo
  file { '/etc/apt/apt.conf.d/99allow_unauthenticated':
    content => 'APT::Get::AllowUnauthenticated yes;'
  }

  # Optional: Local copy of the repo (created after vagrant up) to speed up
  # destroy and reload; to create, from within the VM:
  # cp -r /var/cache/apt/archives/ /vagrant/offline/apt-archives
  # cd /vagrant/apt-archives && dpkg-scanpackages .  > Packages
  apt::source { 'local-repo2speedup-reinstall':
    location => "file:${local_repo}",
    require => File["${local_repo}/Packages"],
  }

}
