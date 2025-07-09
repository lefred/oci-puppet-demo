class innodbcluster::passwords {

 $root_password = $innodbcluster::mysql_root_password
 $user = $innodbcluster::adminuser
 $password = $innodbcluster::adminpassword

  exec {'set_admin_pwd_file':
        command   => "expect -d -c 'set timeout -1; spawn mysql_config_editor set --login-path=client --skip-warn --user=${user} --password; expect \"Enter password:\"; send \"${password}\n\"; expect eof' > /tmp/expect_debug.log 2>&1",
        unless    => "mysql_config_editor print --all | grep -q 'user = \"${user}\"'",
        environment => ['MYSQL_TEST_LOGIN_FILE=/root/.mylogin.cnf', 'HOME=/root'],
        path      => ['/usr/bin', '/usr/libexec/mysqlsh/'],
 }

}
