mw_mysql_master_server root_password: 'master', port: 3306
mw_mysql_slave_server root_password: 'slave', port: 3307, master_host: '127.0.0.1', master_port: 3306, config_file: '/root/.my_slave.cnf'
