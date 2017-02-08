
package { 'dovecot':
  ensure => 'present',
}

$dovecot_conf = @("DOVECOT_CONF")
  disable_plaintext_auth = no
  mail_privileged_group = mail
  mail_location = mbox:~/mail:INBOX=/var/mail/%u
  protocols = "imap"
  ssl_cert_file = "${certdir}/${::fqdn}.crt"
  ssl_key_file  = "${certdir}/${::fqdn}.key"

  auth default {
    mechanisms = plain login
    userdb {
      driver = passwd
    }
    passdb {
      args = %s
      driver = pam
    }
    socket listen {
      master {
  			path = /var/run/dovecot/auth-master
  			mode = 0660
  			#user = root
  			group = mail
  		}
  		client {
  			path = /var/run/dovecot/auth-client
  			mode = 0666
  		}
    }
  }
  | DOVECOT_CONF

file { '/usr/local/etc/dovecot.conf':
  ensure => 'file',
  content => $dovecot_conf,
} ~>
service { 'dovecot':
  ensure => 'running',
  enable => true,
}
