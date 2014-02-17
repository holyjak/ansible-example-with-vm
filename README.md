Example of non-trivial Ansible config with control and test VMs
===============================================================

### Intro

This project has three things of interest:

1. A non-trivial Ansible configuration that demonstrates couple of useful features and tricks
2. A Vagrant/VirtualBox virtual machine with Ansible & co. to make it easy to run it (even on Windows)
3. Another VM that can be used to test the configuration

And of course all the plumbing that makes them work together. It might be therefore a good base for Ansible projects of your own.

*Disclaimer: I am quite new to Ansible.*

### Little background: Ansible and Vagrant

[Ansible](http://docs.ansible.com/) is a devops tool for configuring servers over SSH, using just Python. It is similar to Puppet and Chef but does not need you to install anything on the servers (essentialy every \*nix has Python 2.4+ and SSH, and it even works with the old RHEL 5.9), the configuration is by defaut pushed from the control machine instead of pulled by the servers, and it has strong focus on simplicity. It is less mature than Puppet and has fewer plugins and no support for Windows yet but the simplicity, minimal requirements, and push model are good reasons to consider it.

[Vagrant](http://www.vagrantup.com/) is a command-line tool for creating, configuring, and managing virtual machines, f.ex. using [VirtualBox](https://www.virtualbox.org/). It also integrates them with the host machine by directory sharing, port forwarding, and password-less ssh. In essence, you need few text files and get a fully functional, configured, and integrated environment in a VM.

### Demonstrated features & tricks

#### Vagrant - Ansible integration tips

Set `config.ssh.forward_agent = true` in the `ansible-vm` and use `ssh-agent` to make it easier to make your prive keys available to Ansible for SSH into remote machines. (See "Testing locally" below for more details.)

Add `mount_options: ['dmode=0775','fmode=0664']` for mounting the directory with Ansible configuration so that the inventory file won't seem to be executable to Ansible. (Otherwise Ansible believes it is a script and tries to execute it.)

#### Ansible

*General*: Use roles to split configuration into separate concerns (jboss, vagrant), use variables to handle variation between environments and usages of a role (f.ex. JBoss' ports, `jboss_host_type` = `master|slave`, `env` = `vagrant|staging|production`). Use tags to mark parts of the configuration so that those parts can be picked and executed without the rest (f.ex. `jboss_module`, `jboss_configuration`, `vagrant`).

*Secret local credentials vars file*: the configuration includes variables from the file `secret_vars.yml`, which is added to `.gitignore` so that it won't be checked into Git and every user has to create her own local copy based on `secret_vars.yml.example`. Thus sensitive credentials never leave the local machine.

*Reuse via parametrized include and simulating `creates` for `get_url`*. To avoid the need to keep downloaded archives, I use `stat` to check for the presence of a file/directory and `while` to skip `get_url` if it exists. The whole thing is in a task include file, `roles/jboss/tasks/fetch-module.yml`, that is parametrized so that it can be reused to fetch and unpack three different modules - see `roles/jboss/tasks/modules.yml`.

*Multiple environments* - here`vagrant` and `staging` via two different inventory files.

#### Gotchas

If Ansible seems to freeze while executing a command, make sure that the command is not trying to ask for user input, as was my case with `unzip` that wanted to know what to do with existing files (fixed by running it with `-o` to force overwrite them).

### Automated configuration of JBoss

JBoss configuration using Ansible so it is possible to automatically apply it to a server.
Some of the files (-> templates) are parametrized with variables that are defined f.ex. in
`group_vars/appservers`, the host inventory file (f.ex. `vagrant`), and `secret_vars.yml`.

**BEWARE**: Copy `secret_vars.yml.example` to `secret_vars.yml` and set the right credentials there.

Ansible
-------

### Prerequisities

You will need

* (Windows: ssh, f.ex. the one from the Putty installer)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (f.ex. 4.3.6)
* [Vagrant](http://www.vagrantup.com/) (f.ex. 1.4.3)
* Vagrant vbguest plugin (after having installed vagrant, run `vagrant plugin install vagrant-vbguest`)

### How is it set up

The Vagrant/VirtualBox VM `ansible-vm` has Ansible installed and may be used to run it against the test VM or staging. The test VM itself, `centos-vm`, may be used to test the changes locally before staging.
As described above, you will need to create `secret_vars.yml` with secret credentials.

Under Linux/Mac, you may install and use Ansible directly, without `ansible-vm`.

### Briefly about Vagrant

Vagrant is a command-line tool that can create, set up, and manage VirtualBox virtual machines.

You need to know:

* Run `vagrant up` in `centos-vm` or `ansible-vm` to create, configure, and start the VM
  * Run `vagrant reload` after you did `up` for the first time, if new Guest Additions were installed
* Run `vagrant ssh` to ssh into the machine as the user `vagrant`, which has full sudo rights.
* Run `vagrant halt` to stop a VM and `vagrant destroy` if you want to destroy it (to re-create it from scratch)

Notice that Vagrant automatically shares the vm directory as `/vagrant` with the VM (and we also share this
directory as `/Infrastructure`) and it can forward ports from the guest VM to the host so that you can
access services running in the VM via `locahost:<the forwarded port>` which we use a lot in the `centos-vm`.

### Structure of the configuration

Most of the config is inside "roles" such as "jboss" and "vagrant", see the `./roles/` directory.

### Usage

#### Testing locally

Use the test CentOS VM. To enable password-less execution of ansible against the test
VM, it is recommended to use ssh-agent, adding the vagrant key to it via `ssh-add ~/.vagrant.d/insecure_private_key`.

Windows: Use Git Bash and [enable ssh-agent](https://help.github.com/articles/working-with-ssh-key-passphrases#auto-launching-ssh-agent-on-msysgit) as described in GitHub Help, adding the line `ssh-add ~/.vagrant.d/insecure_private_key` to it. Use the same Bash (?) to run `vagrant up` under `ansible-vm`.

Alternatively, run ansible with `--ask-pass` or `-k`, the password is "vagrant".

1. Run the test `centos-vm` - go to the directory and run `vagrant up`
2. Run `ansible-vm` - go to the directory and run `vagrant up` and then `vagrant ssh`
3. In the Ansible VM run `cd /Infrastructure` and run f.ex. `ansible-playbook -vi vagrant site.yml`

Note: The `ansible-vm` setup assumes that IP of the host machine as visible from the VM is `10.0.2.2` (test with f.ex. `route`)

#### Dry-run

Ansible can try to predict some of the changes it would need to do:

     ansible-playbook -vi staging site.yml -u <your user name> [--ask-sudo-pass] --check --diff

#### Application of changes to staging

Inside the `Infrastructure/` directory, run:

    ansible-playbook -vi staging site.yml -u <your user name> [--ask-pass] [--ask-sudo-pass] [--tags <comma-separated tags>] [--private-key=key file]

Notes:

* Ansible will ssh as the provided user to the machines listed in the staging file
  ("-u jakub" => "ssh jakub@app(1|2).staging.example.com")
* `--ask-pass` is necessary if ssh asks for password, i.e. if you haven't set up password-less ssh
* `--ask-sudo-pass` (or `-K`) is necessary if your user hasn't password-less sudo access on the server
* You can use `--tags` to execute only a subset of the tasks (provided the have been tagged);
  ex.: `--tags jboss_module,jboss_configuration`
