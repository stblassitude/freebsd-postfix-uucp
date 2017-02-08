# A FreeBSD-based Postfix install as a leaf UUCP node

This repo creates a Vagrant box with FreeBSD, Postfix and Dovecot using
test-kitchen and puppet apply. The system can then be instructed to
dial out to a UUCP system via TCP.

## Configuration

A single manifest 01_configuration.pp needs to define a number of puppet
variables for the other manifests to work properly.  The manifest is
.gitignored.

```
# the UUCP node name for this host.  The system hostname default-freebsd
# is likely not correct for the purposes of UUCP.
$uuname = "uutest"
# Login name to use when calling the central UUCP server
$uulogin = "Uuutest"
# Password for above
$uupassword = "ZuMQ5dwtH2gr6"
# UUCP name of the central UUCP server
$uusystem = "uunet"
# FQDN of central UUCP server to connect to via TCP
$uuaddr = "uucp.uu.net
# FQDN of our system, as it is known on the Internet
$uufqdn = "uutest.example.com"
```

## Testing the UUCP connection
After `kitchen converge`, you can `kitchen login`, become root, then
run uucico(8) to start a UUCP exchange with the central server, like so:

```
/usr/local/libexec/uucp/uucico -r 1 -x 9 -f -s uunet
```

You can read and send mail, using the built-in FreeBSD mail(1) client, or by
connecting an IMAP/SMTP client to the host-only network address 192.168.33.33.

The default vagrant users' password is `vagrant`.
