## umcroot

umcroot is a lightweight container using `proot`, allowing you to run Ubuntu or Alpine with root inside anything.

---

## Features

- Install Ubuntu 22.04 or Alpine Linux using proot
- Minimal `init` system to run `/etc/init/*.sh` services
- Works on x86_64 and aarch64 architectures

---

## Requirements

- Linux host
- x86_64 or aarch64 CPU

---

## Quick Start

1. Clone the repository and cd and run the install script:

```sh
git clone https://github.com/PowerEdgeR710/umcroot.git && cd umcroot && bash root.sh
````

Follow the prompts

2. Once inside, you’ll see:

* Memory and storage usage
* Services run and log output to `/etc/init/<service>.log`
* `shell` service running last gives an interactive shell

---

## Using the Init System

* Services are located in `/etc/init/`
* Logs are stored in `/etc/init/<service>.log` (cleared on startup)
* Add your own services:

```sh
nano /etc/init/myservice.sh
chmod +x /etc/init/myservice.sh
exec /init
```
