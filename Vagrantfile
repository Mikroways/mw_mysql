# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.5.0"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

#  if Vagrant.has_plugin?("vagrant-cachier")
#    config.cache.scope = :box
#  end

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
  end

  config.vm.define 'mysql-standalone', primary: true do |app|
    app.vm.hostname = "mysql-standalone.mk.net"
    app.omnibus.chef_version = :latest
    app.vm.box = "chef/ubuntu-14.04"
    app.vm.network :private_network, ip: "10.10.10.10"
    app.berkshelf.enabled = true
    app.vm.provision :chef_zero do |chef|
      chef.json = {
        mw_mysql: {
          tmpdir_size: '128M'
        }
      }
      chef.run_list = [
        "recipe[apt]",
        "recipe[mw_mysql]",
      ]
    end
  end

  config.vm.define 'mysql-master', primary: true do |app|
    app.vm.hostname = "mysql-master.mk.net"
    app.omnibus.chef_version = :latest
    app.vm.box = "chef/ubuntu-14.04"
    app.vm.network :private_network, ip: "10.10.10.11"
    app.berkshelf.enabled = true
    app.vm.provision :chef_zero do |chef|
      chef.json = {
        mw_mysql: {
          tmpdir_size: '128M'
        }
      }
      chef.run_list = [
        "recipe[apt]",
        "recipe[mw_mysql::master]",
      ]
    end
  end

  config.vm.define 'mysql-slave', primary: true do |app|
    app.vm.hostname = "mysql-slave.mk.net"
    app.omnibus.chef_version = :latest
    app.vm.box = "chef/ubuntu-14.04"
    app.vm.network :private_network, ip: "10.10.10.12"
    app.berkshelf.enabled = true
    app.vm.provision :chef_zero do |chef|
      chef.json = {
        mw_mysql: {
          tmpdir_size: '128M',
          master_host: '10.10.10.11'
        }
      }
      chef.run_list = [
        "recipe[apt]",
        "recipe[mw_mysql::slave]",
      ]
    end
  end

end
