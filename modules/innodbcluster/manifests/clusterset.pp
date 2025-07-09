class innodbcluster::clusterset {

  require innodbcluster::magic

  $user = $innodbcluster::adminuser
  $password = $innodbcluster::adminpassword
  $clustername = $innodbcluster::cluster_name

  $members = lookup('innodbcluster::members', Optional[Array[String]], 'first', undef)
  $cluster_node = innodbcluster::seed_node($members, $user)
  $clusterset_members = lookup('innodbcluster::clusterset::members', Optional[Array[String]], 'first', undef)
  $clusterset_name = lookup('innodbcluster::clusterset::name', Optional[String], 'first', undef)
  $clusterset_primary_name = lookup('innodbcluster::clusterset::primary_name', Optional[String], 'first', undef)

  $this_host = $facts['networking']['fqdn']
  $another_host = innodbcluster::seed_clusterset_node($clusterset_members, $user)

  if $this_host in $clusterset_members {
    notice("This node is part of a clusterset")
    if ($clusterset_primary_name == $clustername) {
      notice("This node is part of the primary cluster of the clusterset")
      # let's check if this node is already attached to the clusterset
      if (innodbcluster::clusterset_node($this_host, $user) == false) and ($this_host == $another_host) {
        notice("This node will bootstrap the clusterset")
        if innodbcluster::cluster_node($this_host, $user) == true {
          exec {
              "create_clusterset":
              command => "mysqlsh ${user}@${this_host} -- cluster create-cluster-set \"${clusterset_name}\"",
              path    => ['/usr/bin', '/bin'],
              environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf'],
          }
        } else {
          warning("This node is not part of a cluster yet, it cannot bootstrap the clusterset")
        }
      } else {
        notice("This node is already part of the clusterset")
      }
    } else {
      notice("This node is part of the secondary cluster of the clusterset")
    }
  } else {
    notice("This node is not part of a clusterset")
  }


  exec {
          "create_replica_cluster":
            command => "mysqlsh ${user}@${another_host} --no-wizard -- clusterset create-replica-cluster ${user}@${this_host} \"${clustername}\" --recoveryMethod=clone",
            path    => ['/usr/bin', '/bin'],
            environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf'],
            require => Exec["create_admin_user"],
            refreshonly => true,
            #notify => Exec["change_instance_label"],
  }

}
