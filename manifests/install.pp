# == Class: couchbase::install
#
# Installs the couchbase-server package on server
#
# === Parameters
# [*version*]
# The version of the couchbase package to install
#
# === Authors
#
# Justice London <jlondon@syrussystems.com>
# Portions of code by Lars van de Kerkhof <contact@permanentmarkers.nl>
#
# === Copyright
#
# Copyright 2013 Justice London, unless otherwise noted.
#
class couchbase::install (
  $version           = $couchbase::version,
  $edition           = $couchbase::edition,
  $method            = $couchbase::install_method,
  $download_url_base = $couchbase::download_url_base,
  $package_name      = $couchbase::package_name,
) {
  include couchbase::params

  $pkgname_enterprise = "couchbase-server-enterprise${::couchbase::params::pkgverspacer}${version}-${::couchbase::params::osname}${::couchbase::params::pkgarch}.${::couchbase::params::pkgtype}"
  $pkgname_community = "couchbase-server-community${::couchbase::params::pkgverspacer}${version}-${::couchbase::params::osname}${::couchbase::params::pkgarch}.${::couchbase::params::pkgtype}"

  $pkgname = $edition ? {
        'enterprise' => $pkgname_enterprise,
        'community'  => $pkgname_community,
        default      => $pkgname_community,
    }

  $pkgsource = "${download_url_base}/${version}/${pkgname}"

  case $method {
    'curl': {
      exec { 'download_couchbase':
        command => "curl -o /opt/${pkgname} ${pkgsource}",
        creates => "/opt/${pkgname}",
        path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
      }
      package {'couchbase-server':
        ensure   => installed,
        name     => 'couchbase-server',
        notify   => Exec['couchbase-init'],
        provider => $::couchbase::params::installer,
        require  => [Package[$::couchbase::params::openssl_package], Exec['download_couchbase']],
        source   => "/opt/${pkgname}",
      }
    }
    'package': {
      package { $package_name:
        ensure  => $::couchbase::version,
        name    => $package_name,
        notify  => Exec['couchbase-init'],
        require => Package[$::couchbase::params::openssl_package],
      }
    }
    default: {
      fail ("${module_name} install_method must be 'package' or 'curl'")
    }
  }

  if !defined(Package[join($::couchbase::params::openssl_package,",")]) {
    ensure_packages($::couchbase::params::openssl_package)
  }

}
