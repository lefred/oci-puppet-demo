class innodbcluster::config {

 $root_password = $innodbcluster::mysql_root_password
 $old_root_password = $innodbcluster::mysql_old_root_password

 if $root_password != undef {
   case $old_root_password {
     undef   : { $old_pwd = '' }
     default : { $old_pwd = "-p'${old_root_password}'" }
   }
 }

 exec { 'set_root_pwd':
	      command   => "mysqladmin -u root ${old_pwd} password '${root_password}'",
        logoutput => true,
        unless    => "mysqladmin -u root -p'${root_password}' status > /dev/null",
        path      => '/usr/local/sbin:/usr/bin:/usr/local/bin',
        require   => [ Exec['initialize_mysql'], Service['mysqld'] ],
 }

 exec {'set_root_pwd_file':
        command   => "expect -c 'set timeout -1; spawn mysql_config_editor set --login-path=root@localhost --skip-warn --user=root --password; expect \"Enter password:\"; send \"${root_password}\r\"; expect eof'",
        unless    => "mysql -BN -e 'select user from mysql.user where user = \"root\" and host = \"localhost\"' | grep root > /dev/null",
        environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf', 'HOME=/root'],
        path      => '/usr/bin',
        require   => Exec['set_root_pwd'],
 }

 exec {'set_report_host':
        command   => "mysql -e \"SET PERSIST_ONLY report_host = '${this_host}'; retsart \"",
        environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf', 'HOME=/root'],
        path      => '/usr/bin',
        require   => Exec['set_root_pwd_file'],
        refreshonly => true,
 }


 $mysqlserverid = $innodbcluster::mysql_serverid

 exec {
	"disable-selinux":
       		path    => ["/usr/bin","/bin","/sbin"],
          command => "setenforce 0",
          unless => "getenforce | grep Permissive",
 }

 $my_file="/etc/my.cnf"

 file {
	"my.cnf":
        	path    => $my_file,
          ensure  => present,
          content => template("innodbcluster/my.cnf.erb"),
		      require => Package["mysql-community-server"];

 }

 exec {
 	"initialize_mysql":
          path    => ['/sbin', '/usr/bin', '/bin'],
          unless  => "test -f /var/lib/mysql/ibdata1",
          require => Package["mysql-community-server"],
          notify => Exec["set_report_host"],
          command => "mysqld --initialize-insecure -u mysql --datadir /var/lib/mysql";
 }

}
