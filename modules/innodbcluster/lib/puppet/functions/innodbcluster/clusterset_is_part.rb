# innodbcluster/lib/puppet/functions/innodbcluster/clusterset_is_part.rb

Puppet::Functions.create_function(:'innodbcluster::clusterset_is_part') do
  require 'open3'
  require 'socket'

  dispatch :find_node do
    param 'String', :member
    param 'String', :cluster_name
    optional_param 'String', :user
  end

  def find_node(member, cluster_name, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => '/root/.mylogin.cnf' }
    cmd = ["mysqlsh", "#{user}@#{member}", "--", "clusterset", "status"]

    stdout, stderr, status = Open3.capture3(env, *cmd)

    if status.success? && stdout.include?(cluster_name)
      return true
    end

    return false

  rescue => e
    Puppet.warning("innodbcluster::clusterset_is_part failed: #{e}")
    return false
  end
end