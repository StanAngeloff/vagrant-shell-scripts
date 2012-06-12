vagrant-shell-scripts
=====================

A collection of scripts (Ubuntu-only at this time) to ease Vagrant box provisioning using the [shell][shell] method.

  [shell]: http://vagrantup.com/v1/docs/provisioners/shell.html

Usage
-----

1. Place on top of your `Vagrantfile`:

    ```ruby
    require 'erb'
    ```

2. Place on top of your provisioning script:

    ```bash
    #!/usr/bin/env bash

    # {{{ Utilities

    <%= import 'vagrant-shell-scripts/ubuntu.sh' %>

    # }}}
    ```

    Note the directory `vagrant-shell-scripts` is expected to be next to your provisioning script.

3. Place the code below at the end of your `Vagrantfile` before the closing `end`:

    ```ruby
    # Enable provisioning through a shell script.
    config.vm.provision :shell do |shell|
      relative     = '../_scripts/vagrant/'
      script       = 'provision.sh'
      shell.inline = ERB.new("<% def import(file); File.read('#{relative}' + file); end %>" + File.read("#{relative}#{script}")).result
    end
    ```

    Update `relative` to contain the relative path (from `Vagrantfile`) to your provisioning script.

    Update `script` if you called your provisioning file something different.

Functions
---------

### Utility

- `script-argument-create(value, expected)`

    Return the value of the first argument or exit with an error message if empty.

    Example:

    ```bash
    MYSQL_DBNAME=$( script-argument-create "$1" 'a MySQL database name as the first argument' )
    ```

### Nameservers

- `nameservers-local-purge`

    Drop all local `10.0.x.x` nameservers in `resolv.conf`.

- `nameservers-append(ip)`

    Set up an IP as a DNS name server if not already present in `resolv.conf`.

    Example (set up Google DNS):

    ```bash
    nameservers-local-purge
    nameservers-append '8.8.8.8'
    nameservers-append '8.8.4.4'
    ```

### Aptitude

- `apt-mirror-pick(iso2)`

    Set up a specific two-letter country code as the preferred `aptitude` mirror.

    Example (use Ubuntu Bulgaria as a mirror):

    ```bash
    apt-mirror-pick 'bg'
    ```

- `apt-packages-update`

    Update `aptitude` packages without any prompts.

- `apt-packages-install(package[, package[, ...]])`

    Perform an unattended installation of package(s).

    Example:

    ```bash
    apt-packages-update
    apt-packages-install     \
      apache2-mpm-worker     \
      apache2-suexec-custom  \
      mysql-server-5.1       \
      libapache2-mod-fastcgi \
      php5-cgi
    ```

### Apache

- `apache-modules-enable(module[, module[, ...]])`

    Enable a list of Apache modules. This requires a server restart.

- `apache-modules-disable(module[, module[, ...]])`

    Disable a list of Apache modules. This requires a server restart.

- `apache-sites-enable(name[, name[, ...]])`

    Enable a list of Apache sites. This requires a server restart.

- `apache-sites-disable(name[, name[, ...]])`

    Disable a list of Apache sites. This requires a server restart.

- `[PHP=/path/to/binary] apache-sites-create(name[, path = name[, user = name[, group = user]]])`

    Create a new Apache site and set up Fast-CGI components.

    The function creates a new file under `sites-available/name` where `name` is the first argument to the function.

    To set up Fact-CGI, a new directory `.cgi-bin` is created in `path` if it doesn't already exist.

    The virtual host is pointed to `path` or `/name` if `path` is omitted.

    **SuExec is required** and a user and group options are set up so permissions can work properly.

    If you prefix the function with `PHP=/path/to/binary`, PHP will be enabled through a Fast-CGI script in `.cgi-bin`. You must have PHP installed.

    Example (create a new `vagrant` website from `/vagrant` and enable PHP):

    ```bash
    PHP=/usr/bin/php-cgi apache-sites-create 'vagrant'
    apache-sites-enable vagrant
    apache-restart
    ```

- `apache-restart`

    Restart the Apache server and reload with new configuration.

    Example:

    ```bash
    apache-modules-enable actions rewrite fastcgi suexec
    apache-restart
    ```

### MySQL

- `mysql-database-create(name[, charset = 'utf8'[, collision = 'utf8_general_ci']])`

    Create a database if one doesn't already exist.

- `mysql-database-restore(name, path)`

    Restore a MySQL database from an archived backup.

    This function scans for files in `path` (non-recursive) that match the format:

    ```
    ^[0-9]{8}-[0-9]{4}.tar.bz2$
    ```

    e.g., `20120101-1200.tar.bz2`. The matching files are sorted based on the file name and the newest one is picked.

    If the database `name` is empty, i.e., it doesn't contain any tables, the latest backup is piped to `mysql`.

    Example (where `/database-backups` is shared from `Vagrantfile`):

    ```bash
    mysql-database-restore 'project' '/database-backups'
    ```

- `mysql-remote-access-allow`

    Allow remote passwordless `root` access for anywhere.

    This is only a good idea if the box is configured in 'Host-Only' network mode.

- `mysql-restart`

    Restart the MySQL server and reload with new configuration.

Goal
----

As I explore different OSes, I hope to add support for more platforms.

The functions should remain the same, so provisioning scripts are somewhat 'portable'.

Full Example
------------

The provisioning script below sets up Apache, SuExec, a virtual host for `/vagrant` (the default share) and remote `root` access to MySQL.

```bash
#!/usr/bin/env bash

# {{{ Ubuntu utilities

<%= import 'vagrant-shell-scripts/ubuntu.sh' %>

# }}}

# Use Google Public DNS for resolving domain names.
# The default is host-only DNS which may not be installed.
nameservers-local-purge
nameservers-append '8.8.8.8'
nameservers-append '8.8.4.4'

# Use a local Ubuntu mirror, results in faster downloads.
apt-mirror-pick 'bg'

# Update packages cache.
apt-packages-update

# Install VM packages.
apt-packages-install     \
  apache2-mpm-worker     \
  apache2-suexec-custom  \
  mysql-server-5.1       \
  libapache2-mod-fastcgi \
  php5-cgi               \
  php5-gd                \
  php5-mysql

# Allow modules for Apache.
apache-modules-enable actions rewrite fastcgi suexec

# Replace the default Apache site.
PHP=/usr/bin/php-cgi apache-sites-create 'vagrant'
apache-sites-disable default default-ssl
apache-sites-enable vagrant

# Restart Apache web service.
apache-restart

# Allow unsecured remote access to MySQL.
mysql-remote-access-allow

# Restart MySQL service for changes to take effect.
mysql-restart
```

### Copyright

> Copyright (c) 2012 Stan Angeloff. See [LICENSE.md](https://github.com/StanAngeloff/vagrant-shell-scripts/blob/master/LICENSE.md) for details.
