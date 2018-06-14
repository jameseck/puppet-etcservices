define etcservices::service (
  Pattern[/^[\w\.\-]+\/tcp$/, /^[\w\.\-]+\/udp$/] $service_name = $name,
  Integer                                         $port         = undef,
  String                                          $comment      = '',
  Array[String]                                   $aliases      = [],
  Enum['present', 'absent']                       $ensure       = 'present'
)
{
  $primary_keys = split($name, '/')
  $serv_name = $primary_keys[0]
  $protocol = $primary_keys[1]

  if ($ensure == 'present') {
    $augeas_alias_operations = prefix($aliases, 'set $node/alias[last()+1] ')

    $augeas_pre_alias_operations = [
      "defnode node service-name[.='${serv_name}'][protocol = '${protocol}'] ${serv_name}",
      "set \$node/port ${port}",
      "set \$node/protocol ${protocol}",
      'remove $node/alias',
      'remove $node/#comment'
    ]

    if empty($comment) {
      $augeas_post_alias_operations = []
    } else {
      $augeas_post_alias_operations = [
        "set \$node/#comment '${comment}'"
      ]
    }

    $augeas_operations = flatten([
      $augeas_pre_alias_operations,
      $augeas_alias_operations,
      $augeas_post_alias_operations,
    ])
  }
  else {
    $augeas_operations = [
      "remove service-name[.='${serv_name}'][protocol = '${protocol}'] ${serv_name}"
    ]
  }

  augeas { "${serv_name}_${protocol}":
    incl    => '/etc/services',
    lens    => 'Services.lns',
    changes => $augeas_operations,
  }
}
