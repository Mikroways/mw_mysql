
def mw_mysql_server(instance_name, root_password = 'change me')

  mw_mysql_apply_customizations!

  directory node['mw_mysql']['tmpdir']

  mount node['mw_mysql']['tmpdir'] do
    pass     0
    fstype   "tmpfs"
    device   "/dev/null"
    options  "rw,mode=1777,nr_inodes=10k,size=#{node['mw_mysql']['tmpdir_size']}"
    action   [:mount, :enable]
  end

  mw_mysql_configure_apparmor instance_name

  mysql_service instance_name do
    port '3306'
    initial_root_password root_password
    tmp_dir node['mw_mysql']['tmpdir']
    action [:create, :start]
  end

  mysql_tuning instance_name do
    include_dir "/etc/mysql-#{instance_name}/conf.d"
    notifies :restart, "mysql_service[#{instance_name}]"
  end

  mysql_config 'charset' do
    source 'charset.cnf.erb'
    instance instance_name
    variables(charset: node['mw_mysql']['charset'],
              collation: node['mw_mysql']['collation'])
    notifies :restart, "mysql_service[#{instance_name}]"
  end

  mw_mysql_dot_file root_password
end

def mw_mysql_master_server(options = {root_password: 'change me', replication_password: 'repl', server_id: 1})
  mw_mysql_replication_server("master-#{options[:server_id]}",
                              'replication-master.erb',
                              options)
end

def mw_mysql_slave_server(options = {root_password: 'change me', replication_password: 'repl', server_id: 2})
 mw_mysql_replication_server("slave-#{options[:server_id]}",
                             'replication-slave.erb',
                             options)
 mw_replication_start_slave! options
end

def mw_mysql_replication_server(instance_name, template, options)
  mw_mysql_server instance_name, options[:root_password]

  mysql_config  "Replication #{instance_name}" do
    config_name 'replication'
    instance instance_name
    source template
    variables(server_id: options[:server_id], mysql_instance: instance_name)
    notifies :restart, "mysql_service[#{instance_name}]", :immediately
    action :create
  end

  mw_replication_create_user options
end


def mw_mysql_configure_apparmor(instance_name)
  if ubuntu?
    service "apparmor" do
      service_name 'apparmor'
      action :nothing
    end

    directory instance_name do
      path '/etc/apparmor.d/local/mysql'
      owner 'root'
      group 'root'
      mode '0755'
      recursive true
      action :create
    end

    file "apparmor tmpfs mysql" do
      path "/etc/apparmor.d/local/mysql/#{instance_name}-tmpfs"
      owner 'root'
      group 'root'
      mode '0644'
      content <<-EOT
      #{node['mw_mysql']['tmpdir']}/ r,
      #{node['mw_mysql']['tmpdir']}/** rwk,
      EOT
      notifies :restart, "service[apparmor]", :immediately
    end
  end
end

def mw_mysql_dot_file(password)
  file '/root/.my.cnf' do
    content <<-MYCNF
[client]
  password=#{password}
  host=127.0.0.1
  user=root
    MYCNF
    mode '0600'
  end
end

def mw_mysql_apply_customizations!
  node.set['mysql_tuning']['tuning.cnf']['mysqld']['max_connections'] =
    node['mw_mysql']['max_connections'] if node['mw_mysql']['max_connections']
  node.set['mysql_tuning']['logging.cnf']['mysqld']['expire_logs_days'] =
    node['mw_mysql']['expire_logs_days'] if node['mw_mysql']['expire_logs_days']
end

def mw_replication_create_user(options)
  replication_password  = options[:replication_password]
  bash 'create replication user' do
    code <<-EOF
    /usr/bin/mysql -D mysql -e "CREATE USER 'repl'@'%' IDENTIFIED BY '#{Shellwords.escape(replication_password)}';"
    /usr/bin/mysql -D mysql -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';"
    EOF
    not_if "/usr/bin/mysql -e 'select User,Host from mysql.user' | grep repl"
    action :run
  end
end

def mw_replication_start_slave!(options)
  master_host = options[:master_host] || node[:mw_mysql][:master_host]
  Chef::Application.fatal! "Master host must be specified when configuring slave: nil received as master host" unless master_host
  replication_password  = options[:replication_password]
  ruby_block 'start_slave' do
    block do
      query = ' CHANGE MASTER TO'
      query << " MASTER_HOST='#{master_host}',"
      query << " MASTER_USER='repl',"
      query << " MASTER_PASSWORD='#{Shellwords.escape(replication_password)}';"
      query << ' START SLAVE;'
      shell_out!("echo \"#{query}\" | /usr/bin/mysql")
    end
    not_if "/usr/bin/mysql -e 'SHOW SLAVE STATUS\G' | grep Slave_IO_State"
    action :run
  end
end
