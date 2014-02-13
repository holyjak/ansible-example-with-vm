JBoss Role
==========

Install JBoss in the master-slave setup, using the externally defined
variable `jboss_host_type=(master|slave)` to decide the host type.

Based heavily on https://github.com/ansible/ansible-examples/tree/master/jboss-standalone

Known missing stuff:

* Add a management user so that we can deploy to it via jboss-cli and access the web JBoss Console
