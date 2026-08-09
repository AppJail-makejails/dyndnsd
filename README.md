# dyndnsd.rb

dyndnsd.rb aims to implement a small DynDNS-compliant server in Ruby supporting IPv4 and IPv6 addresses. It has an integrated user and hostname database in its configuration file that is used for authentication and authorization. Besides talking the DynDNS protocol it is able to invoke a so-called updater, a small Ruby module that takes care of supplying the current hostname => ip mapping to a DNS server.

github.com/cmur2/dyndnsd

## How to use this Makejail

```console
$ appjail makejail \
    -j dyndnsd \
    -f gh+AppJail-makejails/dyndnsd \
    -o virtualnet=":<random> address:10.0.0.70 default" \
    -o nat \
    -o expose="5354" \
    -V DYNDNSD_USERS="user1 user2:passwd432" \
    -V DYNDNSD_HOSTS_user1="abc def hij" \
    -V DYNDNSD_HOSTS_user2="abc" \
    -- \
    --dyndnsd_admin_email "admin.example.org" \
    --dyndnsd_nameserver 10.0.0.70
$ appjail start dyndnsd
```

Here we are deploying `dyndnsd` with `nsd` installed in the same jail, however, we are only exposing port `5354`, which is the one used by dyndnsd, but we could also expose port `53` (although this mean that we should set `--dyndnsd_nameserver` to the external IP address). However, in the above example, we assume that nsd is deployed with a forward DNS server such as CoreDNS or DNSMasq that redirects all queries from `home.arpa` domain (default, but can be changed) to `10.0.0.70`. For example, in DNSMasq, you can put the following in your configuration file:

```
server=/home.arpa/10.0.0.70
```

And reload DNSMasq with `service dnsmasq reload`. But for now, there are no entries to resolve beyond those specified in the static zone `home.arpa`. Let's change some entries:

```console
$ fetch -qo - 'http://user2:passwd432@10.0.0.70:5354/nic/update?hostname=abc.dyn.home.arpa&myip=2.1.1.2' && echo
good 2.1.1.2
$ host -t A abc.dyn.home.arpa
abc.dyn.home.arpa has address 2.1.3.2
```

### Arguments (stage: build)

* `dyndnsd_from` (default: `ghcr.io/appjail-makejails/dyndnsd`): Location of OCI image. See also [OCI Configuration](#oci-configuration).
* `dyndnsd_tag` (default: `latest`): OCI image tag. See also [OCI Configuration](#oci-configuration).
* `dyndnsd_admin_email` (mandatory): A domain name which specifies the mailbox of the person responsible for this zone.
* `dyndnsd_config` (default: `files/dyndnsd.yml`): Configuration file for dyndnsd.
* `dyndnsd_do_ip4` (default: `yes`): If yes, NSD listens to IPv4 connections.
* `dyndnsd_do_ip6` (default: `no`): If yes, NSD listens to IPv6 connections.
* `dyndnsd_dyn_domain` (default: `dyn`): The zone (which is concatenated by `dyndnsd_primary_zone`) that dyndnsd will use and control and where the subdomains are located.
* `dyndnsd_expire` (default: `604800`): Value that specifies the upper limit on the time interval that can elapse before the zone is no longer authoritative.
* `dyndnsd_nameserver` (mandatory): Address of server that resolves or forwards queries.
* `dyndnsd_ns_domain` (default: `ns`): The label that points to the name server.
* `dyndnsd_nsd_config` (default: `files/nsd.conf`): Configuration file for NSD.
* `dyndnsd_port` (default: `53`): Answer queries on the specified port.
* `dyndnsd_primary_zone` (default: `home.arpa`): The primary zone controlled by the static zone file. It is also concatenated with the label used by `dyndnsd_dyn_domain` and `dyndnsd_ns_domain`.
* `dyndnsd_refresh` (default: `3600`): Interval before the zone should be refreshed.
* `dyndnsd_retry` (default: `900`): Interval that should elapse before a failed refresh should be retried.
* `dyndnsd_serial` (default: `0`): Integer that specifies the time interval that the resource record may be cached before it should be discarded.
* `dyndnsd_server_count` (default: `0`): Start this many NSD servers. Use 0 to start as many CPUs as you have.
* `dyndnsd_tcp_count` (default: `100`): The maximum number of concurrent, active TCP connections by each server.
* `dyndnsd_tcp_query_count` (default: `0`): The maximum number of queries served on a single TCP connection.
* `dyndnsd_tcp_reject_overflow` (default: `no`): If set to yes, TCP connections made beyond the maximum set by dyndnsd_tcp_count will be dropped immediately (accepted and closed).
* `dyndnsd_ttl` (default: `5m`): Integer that specifies the time interval that the resource record may be cached before it should be discarded.
* `dyndnsd_verbosity` (default: `0`): This value specifies the verbosity level for (non-debug) logging.
* `dyndnsd_zone_file` (default: `files/file.zone`): Static zone file.

### Environment (stage: build)

* `DYNDNSD_HOSTS_<user>` (optional): Space-separated list of hosts that the user will control. The user must be specified in `DYNDNSD_USERS` or this environment variable will be silently ignored. Each host must match `^[a-zA-Z0-9]([-a-zA-Z0-9]{0,61}[a-zA-Z0-9])?$` or it will be silently ignored. Each host is concatenated with the values specified in the arguments `dyndnsd_dyn_domain` and `dyndnsd_primary_zone`.
* `DYNDNSD_REGEX_<user>` (optional): Allow a user to use any hostname that match this regex. Read [this](https://github.com/cmur2/dyndnsd?tab=readme-ov-file#matching-with-a-regular-expression) for details.
* `DYNDNSD_USERS` (optional): Space-separated list of users. Each element specifies a user, but optionally a password can be specified in the format `user:password`. If no password is specified, it will have the same value as the username. If the user doesn't match the regex `^[a-zA-Z0-9][a-zA-Z0-9_]+$`, it's silently ignored.


### Volumes

| Name | Owner | Group | Perm | Type | Mountpoint |
| --- | --- | --- | --- | --- | --- |
| dyndnsd-data | `${PUID}` | `${PGID}` | - | - | /dyndnsd |
| nsd-data | 216 | 216 | - | - | /nsd |

## OCI Configuration

```yaml
build:
  variants:
    - tag: 15.1
      containerfile: Containerfile
      aliases: ["latest"]
      default: true
      args:
        FREEBSD_RELEASE: "15.1"
        NO_PKGCLEAN: "1"
      cache_dirs:
        - "pkgcache0:/var/cache/pkg"
        - "gem:/.cache/gem"
```

## Notes

1. As you have seen, most of the parameters in [Arguments](#arguments) are implemented to configure NSD conveniently, but not all parameters are implemented, only some. See [files/nsd.conf](files/nsd.conf) for more details.
2. This Makejail includes [gh+AppJail-makejails/user-mapping](https://github.com/AppJail-makejails/user-mapping), so `puid` and `pgid` are available as arguments.
