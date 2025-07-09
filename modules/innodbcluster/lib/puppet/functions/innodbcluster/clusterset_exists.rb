
Puppet::Functions.create_function(:'innodbcluster::clusterset_exists') do
  require 'open3'
  require 'socket'

  dispatch :find_seed do
    param 'Array[String]', :members
    optional_param 'String', :user
  end

  def find_seed(members, user = 'root')
    env = { 'MYSQL_TEST_LOGIN_FILE' => File.join(Dir.home, '.mylogin.cnf') }

    members.each do |host|
      cmd = ["mysqlsh", "#{user}@#{host}", "--", "clusterset", "status"]
      stdout, stderr, status = Open3.capture3(env, *cmd)

      if status.success?
        return true
      end
    end

    return false
  rescue => e
    Puppet.warning("innodbcluster::seed_node failed: #{e}")
    false
  end
end
