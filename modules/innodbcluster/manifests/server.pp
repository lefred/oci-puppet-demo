class innodbcluster::server {

    require innodbcluster::serverpackages
    require innodbcluster::config
    require innodbcluster::magic

    include innodbcluster::service

}
