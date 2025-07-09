Puppet::Functions.create_function(:'innodbcluster::cluster_exists') do
  require 'open3'
  require 'json'

  dispatch :find_seed do
    param 'Array[String]', :members
    param 'String', :cluster_name
    optional_param 'String', :user
  end

  def find_seed(members, cluster_name, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => File.join(Dir.home, '.mylogin.cnf') }

    members.each do |host|
      cmd = ["mysqlsh", "#{user}@#{host}", "--", "cluster", "describe"]
      stdout, stderr, status = Open3.capture3(env, *cmd)

      next unless status.success?

      begin
        json = JSON.parse(stdout)
        if cluster_name == json['clusterName']
          Puppet.debug("Cluster '#{cluster_name}' found on host #{host}")
          return true
        end
      rescue JSON::ParserError => e
        Puppet.warning("JSON parsing failed on host #{host}: #{e}")
      end
    end

    return false
  rescue => e
    Puppet.warning("innodbcluster::cluster_exists failed: #{e}")
    false
  end
end
