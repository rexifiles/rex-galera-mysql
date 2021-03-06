package Rex::Galera::Mysql; 
use Rex -base;
use Rex::Ext::ParamLookup;

desc 'Set up a galera node';
task 'setup', sub { 

	my $cluster_addresses = param_lookup "cluster_addresses", "127.0.0.1";  # eg: "192.168.10.10,192.168.10.11"
	my $cluster_name      = param_lookup "cluster_name", "default";         # eg: "myGaleraCluster1"
	my $node_name         = param_lookup "node_name";                       # Patch for now till hostname works. 

	#/***************
	# my $node_name         = param_lookup "node_name", sub {                 # eg: Node1 (defaults to hostname)
				# return run(q!hostname!); };
	# ***************/

	my $master            = param_lookup "master", "no";                    # eg: 'yes'
	my $root_pw           = param_lookup "root_pw", "r00tPass";

	unless ( ! is_installed("mysql-server-5.5") ) {
		say "Backing out as you already have mysql installed";
		exit 1;
	}

	repository "add" => "galera",
		url      => "http://releases.galeracluster.com/debian",
		key_url  => "http://releases.galeracluster.com/GPG-KEY-galeracluster.com",
		distro    => "jessie",
		repository => "main",
		source    => 0;

	update_package_db;

	run qq!echo mysql-wsrep-server-5.6 mysql-server/root_password string ${root_pw} | debconf-set-selections!;
	run qq!echo mysql-wsrep-server-5.6 mysql-server/root_password_again string ${root_pw} | debconf-set-selections!;

	pkg "galera-3",
		ensure    => "latest",
		on_change => sub { 
			say "package was installed/updated"; 
		};

	pkg "galera-arbitrator-3",
		ensure    => "latest",
		on_change => sub { 
			say "package was installed/updated"; 
		};

	pkg "mysql-wsrep-5.6",
		ensure    => "latest",
		on_change => sub { 
			say "package was installed/updated"; 
		};

	file "/etc/mysql/conf.d/galera.cnf",
		content => template("files/etc/mysql/conf.d/galera.tpl", cluster_addresses => "$cluster_addresses", cluster_name => "$cluster_name", node_name => "$node_name"),
		on_change => sub { 
			say "config updated. "; };


	# Add extra parameter if defined as the master (first) node
	if ( $master eq 'yes' ) {
		run qq!service mysql start --wsrep-new-cluster!;
	} else {
		service "mysql" => "start";
	};

	# service mysql => ensure => "started";
};

desc 'Remove galera and mysql server';
task 'clean', sub {

	service mysql => "stopped";

	if ( is_installed("galera-3") ) {
		remove package => "galera-3";
	};

	if ( is_installed("galera-arbitrator-3") ) {
		remove package => "galera-arbitrator-3";
	};

	if ( is_installed("mysql-wsrep-5.6") ) {
		remove package => "mysql-wsrep-5.6";
	};

	# Purge unrequired files
	run(q!apt-get autoremove -y!);

	repository remove => "galera";

}
