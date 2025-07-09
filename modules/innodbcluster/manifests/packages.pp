class innodbcluster::packages {

     if $innodbcluster::mysql_series == "innovation" {
         $repo_option = "--enablerepo=mysql-innovation-community"
     } else {
         $repo_option = ""
     }

 	package {
               "mysql84-community-release":
                    provider => rpm,
                    source => "https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm",
                    ensure => installed;
 	          "mysql-shell":
                    require => Package['mysql84-community-release'],
                    install_options => ["--enablerepo=mysql-tools-innovation-community"],
                    ensure  => "installed";
               "expect":
                    ensure  => "installed";
  	}


}
