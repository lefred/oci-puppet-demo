# innodbcluster/lib/puppet/functions/innodbcluster/clusterset_node.rb

Puppet::Functions.create_function(:'innodbcluster::clusterset_node') do
  require 'open3'
  require 'socket'

  dispatch :find_node do
    param 'String', :member
    optional_param 'String', :user
  end

  def find_node(member, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => File.join(Dir.home, '.mylogin.cnf') }
    cmd = ["mysqlsh", "#{user}@#{member}", "--", "clusterset", "status"]

    stdout, stderr, status = Open3.capture3(env, *cmd)

    if status.success?
        return true
    end

    return false

  rescue => e
    Puppet.warning("innodbcluster::clusterset_node failed: #{e}")
    return false
  end
end