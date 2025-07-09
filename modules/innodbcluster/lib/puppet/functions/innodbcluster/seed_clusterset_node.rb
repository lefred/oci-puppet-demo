# innodbcluster/lib/puppet/functions/innodbcluster/seed_clusterset_node.rb

Puppet::Functions.create_function(:'innodbcluster::seed_clusterset_node') do
  require 'open3'

  dispatch :find_seed do
    param 'Array[String]', :members
    optional_param 'String', :user
  end

  def find_seed(members, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => '/root/.mylogin.cnf' }

    members.each do |host|
      cmd = ["mysqlsh", "#{user}@#{host}", "--", "clusterset", "status"]
      Puppet.debug("Trying to contact #{host} using mysqlsh")
      stdout, stderr, status = Open3.capture3(env, *cmd)

      if status.success?
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
