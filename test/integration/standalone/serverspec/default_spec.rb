require 'spec_helper'

describe 'mw_mysql::default' do
  set :env, HOME: '/root'

  describe port(3306) do
    it { should be_listening }
  end

  describe command('mysql -BNe "show variables"') do
    its(:exit_status) { should eq 0 } # if failed is because /root/.my.cnf is not working
    its(:stdout) { should match(/^innodb_log_files_in_group\t2$/) }
    its(:stdout) { should match(/^+max_connections\t10$/) }
    its(:stdout) { should match(/^expire_logs_days\t5$/) }
    its(:stdout) { should match(/^collation_server\tutf8_general_ci$/) }
  end

  describe file('/var/mysqltmp'), if: host_inventory['virtualization'][:system] == 'vbox' do
    it { should be_mounted.with(type: 'tmpfs') }
  end
end
