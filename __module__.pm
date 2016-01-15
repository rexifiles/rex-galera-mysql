package Rex::Galera::Mysql; 
use Rex -base;
use Rex::Ext::ParamLookup;

desc 'Set up a galera node';
task 'setup', sub { 

	my $cluster_addresses = param_lookup "cluster_addresses", "127.0.0.1";  # eg: "192.168.10.10,192.168.10.11"
	my $cluster_name      = param_lookup "cluster_name", "default";         # eg: "myGaleraCluster1"
	my $node_name         = param_lookup "node_name", sub {                 # eg: Node1 (defaults to hostname)
				return run(q!hostname!); };
	my $master            = param_lookup "master", "no";                    # eg: 'yes'

	unless ( is_installed("mysql-server-5.5") ) {
		say "Backing out as you already have mysql installed";
		exit 1;
	}

	repository "add" => "galera",
		url      => "deb http://releases.galeracluster.com/debian",
		key_url  => "http://releases.galeracluster.com/GPG-KEY-galeracluster.com",
		distro    => "jessie",
		repository => "main",
		source    => 0;

	update_package_db;

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
		service "mysql", start => "systemctl start mysql --wsrep-new-cluster";
		service "mysql" => "start";
	} else {
		service "mysql" => "start";
	};

	service mysql => ensure => "started";
};

desc 'Remove ossec agent';
task 'clean', sub {

	service ossec => "stopped";

	if ( is_installed("galera-3") ) {
		remove package => "galera-3";
	};

	if ( is_installed("galera-arbitrator-3") ) {
		remove package => "galera-arbitrator-3";
	};

	if ( is_installed("mysql-wsrep-5.6") ) {
		remove package => "mysql-wsrep-5.6";
	};

	repository remove => "ossec";

}
