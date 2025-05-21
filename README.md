# Usage
```
usage: ipseq [-hur] [-f <FMT>] [-e <SEQ>...] [-x <SIZE>] <SEQ>...

options:
    -h, --help
            shows usage and exits

    -f, --format <FMT>
            output format (raw,hex,dot)

    -e, --exclude <SEQ>...
            exclude sequence from output (this option can be used multiple times)

    -u, --unique
            add sequence to exclude list after printing it

    -r, --exclude-reserved
            exclude reserved cidrs

    -x, --expand-seq <SIZE>
            if total number of possible ips in exclude sequence is less or equal than SIZE, expand them as individual IPv4/IPv6

    <SEQ>...
            IPv4 | IPv6 | CIDRv4 | CIDRv6 | Rangev4 | Rangev6
```

# Example
```sh
ipseq 192.168.10.0/30
# 192.168.10.0
# 192.168.10.1
# 192.168.10.2
# 192.168.10.3
ipseq 192.168.10.0/30 -e 192.168.10.2/32 -e 192.168.10.3/32
# 192.168.10.0
# 192.168.10.1
ipseq 192.168.10-11.0-1 192.168.5.0/30
# 192.168.10.0
# 192.168.10.1
# 192.168.11.0
# 192.168.11.1
# 192.168.5.0
# 192.168.5.1
# 192.168.5.2
# 192.168.5.3
```
