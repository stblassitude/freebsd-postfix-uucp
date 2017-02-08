#hiera_include('classes')

package { 'postfix':
  ensure => 'present',
}

$postfix_master_cf = @("POSTFIX_MASTER_CF"/)
  smtp      inet  n       -       n       -       -       smtpd
  submission inet n       -       n       -       -       smtpd
    -o smtpd_tls_security_level=may
    -o smtpd_sasl_auth_enable=yes
    -o smtpd_client_restrictions=permit_sasl_authenticated
    -o milter_macro_daemon_name=ORIGINATING
  smtps     inet  n       -       n       -       -       smtpd
    -o smtpd_tls_wrappermode=yes
    -o smtpd_sasl_auth_enable=yes
    -o smtpd_client_restrictions=permit_sasl_authenticated,reject
    -o milter_macro_daemon_name=ORIGINATING
  #628      inet  n       -       n       -       -       qmqpd
  pickup    fifo  n       -       n       60      1       pickup
  cleanup   unix  n       -       n       -       0       cleanup
  qmgr      fifo  n       -       n       300     1       qmgr
  #qmgr     fifo  n       -       n       300     1       oqmgr
  tlsmgr    unix  -       -       n       1000?   1       tlsmgr
  rewrite   unix  -       -       n       -       -       trivial-rewrite
  bounce    unix  -       -       n       -       0       bounce
  defer     unix  -       -       n       -       0       bounce
  trace     unix  -       -       n       -       0       bounce
  verify    unix  -       -       n       -       1       verify
  flush     unix  n       -       n       1000?   0       flush
  proxymap  unix  -       -       n       -       -       proxymap
  proxywrite unix -       -       n       -       1       proxymap
  smtp      unix  -       -       n       -       -       smtp
  # When relaying mail as backup MX, disable fallback_relay to avoid MX loops
  relay     unix  -       -       n       -       -       smtp
  	-o smtp_fallback_relay=
  #       -o smtp_helo_timeout=5 -o smtp_connect_timeout=5
  showq     unix  n       -       n       -       -       showq
  error     unix  -       -       n       -       -       error
  retry     unix  -       -       n       -       -       error
  discard   unix  -       -       n       -       -       discard
  local     unix  -       n       n       -       -       local
  virtual   unix  -       n       n       -       -       virtual
  lmtp      unix  -       -       n       -       -       lmtp
  anvil     unix  -       -       n       -       1       anvil
  scache    unix  -       -       n       -       1       scache
  #
  dovecot   unix  -       n       n       -       -       pipe
  	flags=DRhu user=vmail:mail argv=/usr/local/bin/spamc -u \${recipient} -e /usr/local/libexec/dovecot/deliver -d \${recipient}
  uucp      unix  -       n       n       -       -       pipe
    flags=F user=uucp argv=uux -r -n -z -a\$sender - \$nexthop!rmail (\$recipient)
  | POSTFIX_MASTER_CF

$postfix_main_cf = @("POSTFIX_MAIN_CF"/)
  compatibility_level = 2

  default_transport = uucp:$uusystem

  queue_directory = /var/spool/postfix
  command_directory = /usr/local/sbin
  daemon_directory = /usr/local/libexec/postfix
  data_directory = /var/db/postfix
  mail_owner = postfix
  local_recipient_maps = unix:passwd.byname \$alias_maps
  unknown_local_recipient_reject_code = 550
  mynetworks = 127.0.0.0/8 192.168.33.0/24
  mynetworks_style = host
  mydestination = \$myhostname $uuname $uufqdn
  recipient_delimiter=+
  alias_database = hash:/etc/mail/aliases
  alias_maps = hash:/etc/mail/aliases
  inet_protocols = all

  readme_directory = /usr/local/share/doc/postfix
  sample_directory = /usr/local/etc/postfix
  sendmail_path = /usr/local/sbin/sendmail
  html_directory = /usr/local/share/doc/postfix
  setgid_group = maildrop
  manpage_directory = /usr/local/man
  newaliases_path = /usr/local/bin/newaliases
  mailq_path = /usr/local/bin/mailq

  smtpd_sasl_auth_enable          = yes
  smtpd_sasl_security_options     = noanonymous
  broken_sasl_auth_clients        = yes
  smtpd_sasl_type                 = dovecot
  smtpd_sasl_path                 = /var/run/dovecot/auth-client
  smtpd_sasl_authenticated_header = yes

  smtp_tls_CAfile                 = /usr/local/share/certs/ca-root-nss.crt
  smtp_tls_cert_file              = ${certdir}/${::fqdn}.crt
  smtp_tls_key_file               = ${certdir}/${::fqdn}.key
  smtp_tls_session_cache_database = btree:\$data_directory/smtp_tls_session_cache
  smtp_tls_security_level         = may
  smtpd_tls_CAfile                = /usr/local/share/certs/ca-root-nss.crt
  smtpd_tls_cert_file             = ${certdir}/${::fqdn}.crt
  smtpd_tls_key_file              = ${certdir}/${::fqdn}.key
  smtpd_tls_session_cache_database = btree:\$data_directory/smtpd_tls_session_cache
  smtpd_tls_dh1024_param_file     = \$config_directory/dh_1024.pem
  smtpd_tls_dh512_param_file      = \$config_directory/dh_512.pem
  | POSTFIX_MAIN_CF

$mailer_conf = @("MAILER_CONF"/)
  sendmail   /usr/local/sbin/sendmail
  send-mail  /usr/local/sbin/sendmail
  mailq      /usr/local/sbin/sendmail
  newaliases /usr/local/sbin/sendmail
  | MAILER_CONF

$rc_conf_sendmail = @(RC_CONF_SENDMAIL)
  sendmail_enable="NO"
  sendmail_msp_queue_enable="NO"
  sendmail_outbound_enable="NO"
  sendmail_submit_enable="NO"
  | RC_CONF_SENDMAIL

file { '/etc/rc.conf.d/sendmail':
  ensure  => 'file',
  content => $rc_conf_sendmail,
}

service { 'sendmail':
  ensure => 'stopped',
}

file { '/etc/mail/mailer.conf':
  ensure  => 'file',
  content => $mailer_conf,
}

file { '/usr/local/etc/postfix/master.cf':
  ensure  => 'file',
  content => $postfix_master_cf,
  notify  => Service['postfix'],
}

file { '/usr/local/etc/postfix/main.cf':
  ensure  => 'file',
  content => $postfix_main_cf,
  notify  => Service['postfix'],
}

exec { '/etc/mail/aliases.db':
  command => '/usr/bin/newaliases',
  unless  => '[ -f /etc/mail/aliases.db -a /etc/mail/aliases -ot /etc/mail/aliases.db ]',
  path    => [ '/usr/local/bin', '/usr/bin', '/bin' ],
}

exec { '/usr/local/etc/postfix/dh_512.pem':
  command => 'openssl dhparam -out /usr/local/etc/postfix/dh_512.pem 512',
  creates => '/usr/local/etc/postfix/dh_512.pem',
  path    => [ '/usr/local/bin', '/usr/bin', '/bin' ],
}

exec { '/usr/local/etc/postfix/dh_1024.pem':
  command => 'openssl dhparam -out /usr/local/etc/postfix/dh_1024.pem 1024',
  creates => '/usr/local/etc/postfix/dh_1024.pem',
  path    => [ '/usr/local/bin', '/usr/bin', '/bin' ],
}

service { 'postfix':
  ensure => 'running',
  enable => true,
}


$uucp_conf = @("UUCP_CONF")
  uuname	$uuname
  command-path	/bin /usr/bin /usr/local/bin
  commands	rmail rnews rgsmtp rcsmtp grsmtp crsmtp bsmtp rsmtp crsmtp
  | UUCP_CONF

package { 'freebsd-uucp':
  ensure => 'present',
}

file { '/usr/local/etc/uucp/call':
  ensure => 'file',
  owner  => 'uucp',
  mode   => '0440',
  content => "$uusystem $uulogin $uupassword\n",
}

file { '/usr/local/etc/uucp/config':
  ensure => 'file',
  owner  => 'uucp',
  mode   => '0444',
  content => $uucp_conf,
}

file { '/usr/local/etc/uucp/port':
  ensure => 'file',
  owner  => 'uucp',
  mode   => '0440',
  content => "port TCP\ntype tcp\n",
}

file { '/usr/local/etc/uucp/sys':
  ensure => 'file',
  owner  => 'uucp',
  mode   => '0440',
  content => "system $uusystem\naddress $uuaddr\ntime any\ncall-login *\ncall-password *\n",
}
