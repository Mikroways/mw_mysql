require 'spec_helper'

describe 'integration_test::master_slave' do
  describe port(3306) do
    it { should be_listening }
  end
  describe port(3307) do
    it { should be_listening }
  end

  describe command('mysql --defaults-file=/root/.my_slave.cnf -Ee "show slave status"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/Slave_IO_State: Waiting for master to send event/) }
    its(:stdout) { should match(/Master_Host: 127\.0\.0\.1$/) }
    its(:stdout) { should match(/Master_User: repl/) }
    its(:stdout) { should match(/Master_Port: 3306/) }
    its(:stdout) { should match(/Slave_IO_Running: Yes/) }
    its(:stdout) { should match(/Slave_SQL_Running: Yes/) }
  end
end
