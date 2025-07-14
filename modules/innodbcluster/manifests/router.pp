class innodbcluster::router (
    $members = lookup('innodbcluster::members', Optional[Array[String]], 'first', undef),
    $adminuser="clusteradmin",
    $adminpassword=$innodbcluster::adminpassword
) {

   include innodbcluster::packages



   if $innodbcluster::mysql_series == "innovation" {
         $repo_option = "--enablerepo=mysql-tools-innovation-community"
   } else {
         $repo_option = ""
   }

   package { 'mysql-router':
     ensure => installed,
     install_options => [$repo_option],
     require => Package['mysql84-community-release'],
   }

   $cluster_node = innodbcluster::bootstrap_candidate($members, $adminuser)
   if $cluster_node == undef {
        warning("No suitable cluster node found in members: ${members.join(', ')}")
   } else {
    exec {
      'bootstrap_mysql_router':
        command => "expect -c 'set timeout -1; spawn mysqlrouter --bootstrap ${adminuser}@${cluster_node}  --user=mysqlrouter --conf-use-gr-notifications 1; expect \"Please enter MySQL password for ${adminuser}:\"; send \"${adminpassword}\r\"; expect eof'",
        path    => ['/usr/bin', '/bin'],
        creates  => "/etc/mysqlrouter/mysqlrouter.configured",
        require => [ Package['mysql-router'], Exec['set_admin_pwd_file'], Package['mysql-shell'] ],
        notify => File['/etc/mysqlrouter/mysqlrouter.configured'],
    }

    file { '/etc/mysqlrouter/mysqlrouter.configured':
        ensure => file,
        owner  => 'mysqlrouter',
        group  => 'mysqlrouter',
        mode   => '0644',
        content => "This file is created by Puppet to indicate that MySQL Router has been configured.\n",
    }

    service { 'mysqlrouter':
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
        require => Exec['bootstrap_mysql_router'],
    }

    exec { 'open_firewall_ports':
        command => "firewall-cmd --zone=public --add-port=6446-64450/tcp --permanent && firewall-cmd --reload",
        path    => ['/usr/bin', '/bin'],
        unless  => "firewall-cmd --list-ports | grep -q '6446/tcp'",
        require => Service['mysqlrouter'],
    }
   }
}

