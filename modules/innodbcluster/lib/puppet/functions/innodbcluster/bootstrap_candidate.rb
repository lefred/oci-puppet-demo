Puppet::Functions.create_function(:'innodbcluster::bootstrap_candidate') do
  require 'open3'

  dispatch :find_candidate do
    param 'Array[String]', :members
    optional_param 'String', :user
  end

  def find_candidate(members, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => '/root/.mylogin.cnf' }

    members.each do |host|
      cmd = ["mysqlsh", "#{user}@#{host}", "--", "cluster", "describe"]
      stdout, stderr, status = Open3.capture3(env, *cmd)

      next unless status.success?

      return host
    end

    return nil
  rescue => e
    Puppet.warning("innodbcluster::bootstrap_candidate failed: #{e}")
    nil
  end
end