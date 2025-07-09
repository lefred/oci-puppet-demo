class innodbcluster::serverpackages {

     if $innodbcluster::mysql_series == "innovation" {
         $repo_option = "--enablerepo=mysql-innovation-community"
     } else {
         $repo_option = ""
     }

 	package {
               "mysql-community-server":
                    require => Package['mysql84-community-release'],
                    install_options => [$repo_option],
                    ensure  => "installed";
  }


}
