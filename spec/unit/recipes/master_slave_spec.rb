
require 'spec_helper'

describe 'integration_test::master_slave' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new
      runner.converge(described_recipe)
    end

    before do
       stub_command("/usr/bin/mysql --defaults-file=/root/.my.cnf -e 'select User,Host from mysql.user' | grep repl").and_return(false)
       stub_command("/usr/bin/mysql --defaults-file=/root/.my_slave.cnf -e 'select User,Host from mysql.user' | grep repl").and_return(false)
       stub_command("/usr/bin/mysql --defaults-file=/root/.my_slave.cnf -Ee 'SHOW SLAVE STATUS' | grep Slave_IO_State").and_return(false)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'set logs attributes' do
      expect(chef_run.node['mw_mysql']['master-1']['log_dir']).to eq '/var/log/mysql-master-1'
      expect(chef_run.node['mw_mysql']['slave-2']['log_dir']).to eq '/var/log/mysql-slave-2'
    end
  end
end
