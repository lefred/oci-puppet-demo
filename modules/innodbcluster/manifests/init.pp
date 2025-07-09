class innodbcluster (
    $mysql_root_password=undef,
    $mysql_old_root_password=undef,
    $mysql_serverid=undef,
    $adminuser="clusteradmin",
    $adminpassword=undef,
    $ensure="running",
    $cluster_name="mycluster",
    $mysql_series="tls",
                    ) {
    notice("Welcome in MySQL InnoDB Cluster Experience !")
    debug("Welcome in MySQL InnoDB Cluster Experience !")

    include innodbcluster::packages
    include innodbcluster::passwords

}
