# innodbcluster/lib/puppet/functions/innodbcluster/seed_node.rb

Puppet::Functions.create_function(:'innodbcluster::seed_node') do
  require 'open3'

  dispatch :find_seed do
    param 'Array[String]', :members
    optional_param 'String', :user
  end

  def find_seed(members, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => '/root/.mylogin.cnf' }

    members.each do |host|
      cmd = ["mysqlsh", "#{user}@#{host}", "--", "cluster", "status"]
      Puppet.warning("Trying to contact #{host} using mysqlsh")
      stdout, stderr, status = Open3.capture3(env, *cmd)
      Puppet.warning("TURISHIP1: #{stdout}")
      Puppet.warning("TURISHIP2: #{stderr}")
      Puppet.warning("TURISHIP3: #{cmd}")

      if status.success?
        Puppet.warning("Success we found a cluster on #{host}")
        return host
      end
    end

    fqdn = call_function('getvar', 'facts.networking.fqdn')
    Puppet.warning("Fallback to agent FQDN: #{fqdn}")
    fqdn
  rescue => e
    Puppet.warning("innodbcluster::seed_node failed: #{e}")
    nil
  end
end
