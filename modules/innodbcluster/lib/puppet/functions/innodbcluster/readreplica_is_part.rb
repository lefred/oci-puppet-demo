# innodbcluster/lib/puppet/functions/innodbcluster/readreplica_is_part.rb

Puppet::Functions.create_function(:'innodbcluster::readreplica_is_part') do
  require 'open3'
  require 'json'

  dispatch :find_readreplica do
    param 'String', :this_host
    param 'String', :cluster_name
    optional_param 'String', :user
  end

  def find_readreplica(this_host, cluster_name, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => '/root/.mylogin.cnf' }

    cmd = ["mysqlsh", "#{user}@#{this_host}", "--", "cluster", "describe"]
    stdout, stderr, status = Open3.capture3(env, *cmd)

    return false unless status.success?

    begin
      json = JSON.parse(stdout)

      # Ensure the cluster name matches
      return false unless json['clusterName'] == cluster_name

      nodes = json.dig("defaultReplicaSet", "topology") || []
      nodes.each do |node|
        label = node["label"]
        if label && label.start_with?(this_host)
          Puppet.debug("Found node #{label} with role #{node['role']}")
          return node["role"]
        end
      end

    rescue JSON::ParserError => e
      Puppet.warning("JSON parsing failed: #{e}")
    end

    false
  rescue => e
    Puppet.warning("innodbcluster::readreplica_is_part failed: #{e}")
    false
  end
end
