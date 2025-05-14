# Usage
```
usage: ipseq [-hur] [-f <FMT>] [-e <CIDR>...] <CIDR>...

options:
    -h, --help
            shows usage and exits

    -f, --format <FMT>
            output format (raw,hex,dot)

    -e, --exclude <CIDR>...
            exclude cidr from output (this options can be used multiple times)

    -u, --unique
            add cidr to exclude list after printing it

    -r, --exclude-reserved
            exclude reserved cidrs

    <CIDR>...

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
```
