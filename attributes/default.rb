default['mw_mysql']['tmpdir'] = '/var/mysqltmp'
default['mw_mysql']['tmpdir_size'] = '2G'

default['mw_mysql']['charset'] = 'utf8'
default['mw_mysql']['collation'] = 'utf8_general_ci'

# si no se define lo calcula mysql_tuning
default['mw_mysql']['max_connections'] = nil
default['mw_mysql']['expire_logs_days'] = nil

default['mw_mysql']['master_host'] = nil
