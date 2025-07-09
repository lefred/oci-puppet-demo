class innodbcluster::readreplica {

  require innodbcluster::packages
  require innodbcluster::serverpackages
  require innodbcluster::config

  $user = $innodbcluster::adminuser
  $password = $innodbcluster::adminpassword
  $clustername = $innodbcluster::cluster_name

  $members = lookup('innodbcluster::members', Optional[Array[String]], 'first', undef)

  $this_host = $facts['networking']['fqdn']

  # check if this node is already part of the cluster as read replica
  if !innodbcluster::readreplica_is_part($this_host, $clustername, $user) {
    notice("This node will try to join the cluster ${clustername} as read replica")
    # check is the cluster is already created
    if !innodbcluster::cluster_exists($members, $clustername, $user) {
      warning("The cluster ${clustername} does not exist or not part of ${members.join(', ')}, cannot create a read replica")
    } else{
      $another_host = innodbcluster::seed_node($members, $user)
      notice("This node will join the cluster as read replica using the seed node: ${another_host}")

      exec {
        "create_read_replica":
          command => "mysqlsh ${user}@${another_host} -- cluster add-replica-instance ${this_host} --recoveryMethod=clone",
          path    => ['/usr/bin', '/bin'],
          environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf'],
          require => Exec["create_admin_user"],
      }
    }
  }
}

