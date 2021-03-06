class nova::db(
  $password,
  $dbname = 'nova',
  $user = 'nova',
  $host = '127.0.0.1',
  $allowed_hosts = undef,
  $cluster_id = 'localzone'
) {

  require 'mysql::python'
  # Create the db instance before openstack-nova if its installed
  Mysql::Db[$dbname] -> Anchor<| title == "nova-start" |>
  Mysql::Db[$dbname] ~> Exec<| title == 'initial-db-sync' |>

  # TODO - worry about the security implications
  # I am not sure if I want to use storeconfigs for this...
  @@nova_config { 'database_url':
    value => "mysql://${user}:${password}@${host}/${dbname}",
    tag   => $zone,
  }

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => 'latin1',
    # I may want to inject some sql
    require      => Class['mysql::server'],
  }

  if $allowed_hosts {
     nova::db::host_access { $allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  } else {
    Nova::Db::Host_access<<| tag == $cluster_id |>>
  }
}
