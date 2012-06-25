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

- `apt-packages-repository(repository[, repository[, ...]][, key[, server = 'keyserver.ubuntu.com']])`

    Add a custom repository as a software source.

    Each `repository` is a line as it would appear in your `/etc/apt/sources.list` file, e.g., <nobr>`deb URL DISTRIBUTION CATEGORY`</nobr>.

    `key` and `server` are the signing key and server.
    You need to add the key to your system so Ubuntu can verify the packages from the repository.

    Example (install MongoDB from official repositories):

    ```
    apt-packages-repository 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' '7F0CEB10'
    apt-packages-update
    apt-packages-install mongodb-10gen
    ```

- `apt-packages-ppa(repository[, key[, server = 'keyserver.ubuntu.com']])`

    Add a Launchpad PPA as a software source.

    The `repository` is the Launchpad user and project name, e.g., `chris-lea/node.js`.

    `key` and `server` are the signing key and server.
    You need to add the key to your system so Ubuntu can verify the packages from the PPA.

    Example (install Node.js from unofficial PPA):

    ```bash
    apt-packages-ppa 'chris-lea/node.js' 'C7917B12'
    apt-packages-update
    apt-packages-install \
      nodejs             \
      npm
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

- `apt-packages-purge(package[, package[, ...]])`

    Perform an unattended complete removal (purge) of package(s).

    Example (purge `apache2` unnecessarily installed as part of the `php5` meta-package):

    ```bash
    apt-packages-update
    apt-packages-install php5
    apt-packages-purge 'apache2*'
    ```

### System

- `system-upgrade()`

    Run a complete system (distribution) upgrade.

    Example:

    ```bash
    apt-packages-update
    system-upgrade
    ```

- `system-service(name, action)`

    Command a system service, e.g., `apache2`, `mysql`, etc.

    Example:

    ```bash
    system-service php5-fpm restart
    ```

- `system-escape`

    Escape and normalize a string so it can be used safely in file names, etc.

    Example:

    ```bash
    echo "Hello World!" | system-escape  # prints 'hello-world'
    ```

### Default Commands

- `alternatives-ruby-install(version[, bin_path = '/usr/bin/'[, man_path = '/usr/share/man/man1/'[, priority = 500]]])`

    Update the Ruby binary link to point to a specific version.

    Example:

    ```bash
    apt-packages-install \
      ruby1.9.1          \
      ruby1.9.1-dev      \
      rubygems1.9.1
    alternatives-ruby-install 1.9.1
    ```

- `alternatives-ruby-gems()`

    Create symbolic links to RubyGems binaries.

    By default, RubyGems on Ubuntu does not create binaries on `$PATH`.
    Using this function would create a symbolic link in the directory of your `ruby` binary which is assumed to be on `$PATH`.

    Example (install stable versions of Sass and link it as `/usr/bin/sass`):

    ```bash
    apt-packages-install \
      ruby1.9.1          \
      ruby1.9.1-dev      \
      rubygems1.9.1
    alternatives-ruby-install 1.9.1
    github-gems-install 'nex3/sass'
    alternatives-ruby-gems 'sass'
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

### Nginx

- `nginx-sites-enable(name[, name[, ...]])`

    Enable a list of Nginx sites. This requires a server restart.

- `nginx-sites-disable(name[, name[, ...]])`

    Disable a list of Nginx sites. This requires a server restart.

- `[PHP=any-value] nginx-sites-create(name[, path = name[, user = name[, group = user[, index = 'index.html']]]])`

    Create a new Nginx site and set up Fast-CGI components.

    The function creates a new file under `sites-available/name` where `name` is the first argument to the function.

    The virtual host is pointed to `path` or `/name` if `path` is omitted.

    If you prefix the function with `PHP=any-value`, PHP will be enabled through a PHP-FPM. You must have `php5-fpm` installed.

    The arguments `user` and `group` are used to re-configure PHP-FPM's default `www` pool to run under the given account.

    You can optionally specify space-separated directory index files to look for if a file name wasn't specified in the request.

    Example (create a new `vagrant` website from `/vagrant` and enable PHP):

    ```bash
    PHP=/usr/bin/php5-fpm nginx-sites-create 'vagrant'
    nginx-sites-enable vagrant
    nginx-restart
    ```

### PHP

- `php-settings-update(name, value)`

    Update a PHP setting value in all instances of 'php.ini'.

    Example (create a default timezone):

    ```bash
    php-settings-update 'date.timezone' 'Europe/London'
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

### RubyGems

- `ruby-gems-install(package[, package[, ...]])`

    Perform an unattended installation of package(s).

    Example:

    ```bash
    apt-packages-install \
      ruby1.9.1          \
      ruby1.9.1-dev      \
      rubygems1.9.1
    alternatives-ruby-install 1.9.1
    ruby-gems-install pkg-config
    ```

### NPM (Node Package Manager)

- `npm-packages-install(package[, package[, ...]])`

    Perform an unattended **global** installation of package(s).

    Example (install UglifyJS):

    ```bash
    apt-packages-ppa 'chris-lea/node.js' 'C7917B12'
    apt-packages-update
    apt-packages-install \
      nodejs             \
      npm
    npm-packages-install uglify-js
    ```

### GitHub

- `github-gems-install(repository[, repository[, ...]])`

    Download and install RubyGems from GitHub.

    The format of each `repository` is `user/project[@branch]` where `branch` can be omitted and defaults to `master`.

    Example (install unstable versions of Sass and Compass):

    ```bash
    apt-packages-install \
      ruby1.9.1          \
      ruby1.9.1-dev      \
      rubygems1.9.1
    alternatives-ruby-install 1.9.1
    github-gems-install              \
      'ttilley/fssm'                 \
      'nex3/sass@master'             \
      'wvanbergen/chunky_png'        \
      'chriseppstein/compass@master'
    ```

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
