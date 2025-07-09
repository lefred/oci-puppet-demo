class innodbcluster::magic {

  require innodbcluster::packages
  require innodbcluster::serverpackages
  require innodbcluster::config

  $user = $innodbcluster::adminuser
  $password = $innodbcluster::adminpassword
  $clustername = $innodbcluster::cluster_name

  $members = lookup('innodbcluster::members', Optional[Array[String]], 'first', undef)
  $cluster_node = innodbcluster::seed_node($members, $user)
  $this_host = $facts['networking']['fqdn']

  $short_host = split($this_host, '.')[0]
  $host_with_port = "${short_host}:3306"

  if defined(Class['innodbcluster::clusterset']) {
     $clusterset_primary_name = lookup('innodbcluster::clusterset::primary_name', Optional[String], 'first', undef)
     if $clusterset_primary_name == $clustername {
       $cluster_can_be_deployed = true
       $this_is_a_read_replica = false
     } else {
       $cluster_can_be_deployed = false
       $this_is_a_read_replica = false
     }
  } else {
    if defined(Class['innodbcluster::readreplica']) {
      $cluster_can_be_deployed = false
      $this_is_a_read_replica = true
    } else {
      $cluster_can_be_deployed = true
      $this_is_a_read_replica = false
    }
  }



  exec {
   "create_admin_user":
         command => "mysqlsh --login-path=root@localhost --no-wizard root@localhost -- dba configure-instance --clusterAdmin=${user} --clusterAdminPassword='${password}' --restart=true && /bin/sleep 5",
         path    => ['/usr/bin', '/bin'],
         environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf'],
         unless  => "mysql --login-path=root@localhost -BN -e 'select user from mysql.user where user = \"${user}\" and host = \"%\"' | grep $user > /dev/null";
  "change_instance_label":
            command => "mysqlsh ${user}@${this_host} --no-wizard -- cluster set-instance-option ${host_with_port} label ${this_host}",
            path    => ['/usr/bin', '/bin'],
            environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf'],
            refreshonly => true,
  }


  if $cluster_node == undef {
    warning("A second puppet run is required to join the cluster")
  } else {

    if $cluster_node == $this_host {
      if (innodbcluster::cluster_node($cluster_node, $user) == false) and ($cluster_can_be_deployed) {
        notice("This node will bootstrap of the cluster")
        exec {
          "create_cluster":
            command => "/bin/sleep 5 && mysqlsh ${user}@${this_host} -- dba createCluster \"${clustername}\"",
            path    => ['/usr/bin', '/bin'],
            environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf'],
            require => Exec["create_admin_user"],
            notify => Exec["change_instance_label"],
        }
      } else {
        $clusterset_members = lookup('innodbcluster::clusterset::members', Optional[Array[String]], 'first', undef)
        if innodbcluster::clusterset_exists($clusterset_members, $user) and
            !innodbcluster::clusterset_is_part($cluster_node, $clustername, $user) {
          notify { 'This node will be the seed of a secondary cluster of a clusterset':
            notify => Exec['create_replica_cluster'],
          }
        }
      }
    } else {
      if !$this_is_a_read_replica {
        unless innodbcluster::cluster_node($this_host, $user) {
          notice("This node will join the cluster using ${cluster_node} as seed node")
        }
        exec {
          "add_instance_cluster":
            command => "mysqlsh ${user}@${cluster_node} --no-wizard -- cluster add-instance ${user}@${this_host} --recoveryMethod=clone",
            path    => ['/usr/bin', '/bin'],
            environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf'],
            require => Exec["create_admin_user"],
            notify => Exec["change_instance_label"],
            unless  => "mysqlsh ${user}@${this_host} --no-wizard -- cluster describe | grep '${this_host}:'",
        }
      }
    }
  }
}
