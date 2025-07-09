# innodbcluster/lib/puppet/functions/innodbcluster/cluster_node.rb

Puppet::Functions.create_function(:'innodbcluster::cluster_node') do
  require 'open3'
  require 'socket'

  dispatch :find_node do
    param 'String', :member
    optional_param 'String', :user
  end

  def find_node(member, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => '/root/.mylogin.cnf' }
    cmd = ["mysqlsh", "#{user}@#{member}", "--", "cluster", "status"]

    stdout, stderr, status = Open3.capture3(env, *cmd)

    if status.success?
        return true
    end

    return false

  rescue => e
    Puppet.warning("innodbcluster::cluster_node failed: #{e}")
    return false
  end
end