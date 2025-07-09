# innodbcluster/lib/puppet/functions/innodbcluster/seed_node.rb

Puppet::Functions.create_function(:'innodbcluster::seed_node') do
  require 'open3'
  require 'socket'
  require 'resolv'

  dispatch :find_seed do
    param 'Array[String]', :members
    optional_param 'String', :user
  end

  def find_seed(members, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => '/root/.mylogin.cnf' }

    members.each do |host|
      cmd = ["mysqlsh", "#{user}@#{host}", "--", "cluster", "status"]
      stdout, stderr, status = Open3.capture3(env, *cmd)

      if status.success?
        return host
      end
    end

    Resolv.getname(Socket.gethostname)
  rescue => e
    Puppet.warning("innodbcluster::seed_node failed: #{e}")
    nil
  end
end
