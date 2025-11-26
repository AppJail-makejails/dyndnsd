# dyndnsd

dyndnsd.rb aims to implement a small DynDNS-compliant server in Ruby supporting IPv4 and IPv6 addresses. It has an integrated user and hostname database in its configuration file that is used for authentication and authorization. Besides talking the DynDNS protocol it is able to invoke a so-called updater, a small Ruby module that takes care of supplying the current hostname => ip mapping to a DNS server.

github.com/cmur2/dyndnsd

## How to use this Makejail

```sh
appjail makejail \
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
```

Here we are deploying `dyndnsd` with `nsd` installed in the same jail, however, we are only exposing port `5354`, which is the one used by dyndnsd, but we could also expose port `53` (although this mean that we should set `--dyndnsd_nameserver` to the external IP address). However, in the above example, we assume that nsd is deployed with a forward DNS server such as CoreDNS or DNSMasq that redirects the all queries from `home.arpa` domain (default, but can be changed) to `10.0.0.70`. For example, in DNSMasq, you can put the following in your configuration file:

```
server=/home.arpa/10.0.0.70
```

And reload DNSMasq with `service dnsmasq reload`. But for now, there are no entries to resolve beyond those specified in the static zone `home.arpa`. Let's change some entries:

```console
$ fetch -qo - 'http://user2:passwd432@10.0.0.70:5354/nic/update?hostname=abc.dyn.home.arpa&myip=2.1.1.2' && echo
good 2.1.1.2
$ host -t A abc.dync.home.arpa
abc.dyn.home.arpa has address 2.1.3.2
```

### Arguments

* `dyndnsd_admin_email` (mandatory): A domain name which specifies the mailbox of the person responsible for this zone.
* `dyndnsd_nameserver` (mandatory): Address of server that resolves or forwards queries.
* `dyndnsd_config` (default: `files/dyndnsd.yml`): configuration file for dyndnsd.
* `dyndnsd_nsd_config` (default: `files/nsd.conf`): Configuration file for NSD.
* `dyndnsd_zone_file` (default: `files/file.zone`): Static zone file.
* `dyndnsd_server_count` (default: `0`): Start this many NSD servers. Use `0` to start as many CPUs as you have.
* `dyndnsd_do_ip4` (default: `yes`): If yes, NSD listens to IPv4 connections.
* `dyndnsd_do_ip6` (default: `no`): If yes, NSD listens to IPv6 connections
* `dyndnsd_port` (default: `53`): Answer queries on the specified port.
* `dyndnsd_verbosity` (default: `0`): This value specifies the verbosity level for (non-debug) logging.
* `dyndnsd_tcp_count` (default: `100`): The maximum number of concurrent, active TCP connections by each server.
* `dyndnsd_tcp_reject_overflow` (default: `no`): If set to yes, TCP connections made beyond the maximum set by `dyndnsd_tcp_count` will be dropped immediately (accepted and closed).
* `dyndnsd_tcp_query_count` (default: `0`): The maximum number of queries served on a single TCP connection.
* `dyndnsd_primary_zone` (default: `home.arpa`): The primary zone controlled by the static zone file. It is also concatenated with the label used by `dyndnsd_dyn_domain` and `dyndnsd_ns_domain`.
* `dyndnsd_dyn_domain` (default: `dyn`): The zone (which is concatenated by `dyndnsd_primary_zone`) that `dyndnsd` will use and control and where the subdomains are located.
* `dyndnsd_ns_domain` (default: `ns`): The label that points to the name server.
* `dyndnsd_ttl` (default: `5m`): Integer that specifies the time interval that the resource record may be cached before it should be discarded.
* `dyndnsd_serial` (default: `0`): Version number for the DNS zone file.
* `dyndnsd_refresh` (default: `3600`): Interval before the zone should be refreshed.
* `dyndnsd_retry` (default: `900`): Interval that should elapse before a failed refresh should be retried.
* `dyndnsd_expire` (default: `604800`): Value that specifies the upper limit on the time interval that can elapse before the zone is no longer authoritative.
* `dyndnsd_ajspec` (default: `gh+AppJail-makejails/dyndnsd`): Entry point where the `appjail-ajspec(5)` file is located.
* `dyndnsd_tag` (default: `13.5`): see [#tags](#tags).

**Note**: As you have seen, most of the above parameters are implemented to configure NSD conveniently, but not all parameters are implemented, only some. See [files/nsd.conf](files/nsd.conf) for more details.

### Environment

* `DYNDNSD_USERS` (optional): Space-separated list of users. Each element specifies a user, but optionally a password can be specified in the format `user:password`. If no password is specified, it will have the same value as the username. If the user doesn't match the regex `^[a-zA-Z0-9][a-zA-Z0-9_]+$`, it's silently ignored.
* `DYNDNSD_HOSTS_<user>` (optional): Space-separated list of hosts that the user will control. The user must be specified in `DYNDNSD_USERS` or this environment variable will be silently ignored. Each host must match `^[a-zA-Z0-9]([-a-zA-Z0-9]{0,61}[a-zA-Z0-9])?$` or it will be silently ignored. Each host is concatenated with the values specified in the arguments `dyndnsd_dyn_domain` and `dyndnsd_primary_zone`.

### Volumes

| Name         | Owner | Group | Perm | Type | Mountpoint  |
| ------------ | ----- | ----- | ---- | ---- | ----------- |
| nsd-data     | 216   | 216   |  -   |  -   | /nsd        |
| dyndnsd-data | 1001  | 1001  |  -   |  -   | /dyndnsd    |

## Tags

| Tag           | Arch    | Version            | Type   |
| ------------- | --------| ------------------ | ------ |
| `13.5`    | `amd64` | `13.5-RELEASE` | `thin` |
| `14.3`    | `amd64` | `14.3-RELEASE` | `thin` |
