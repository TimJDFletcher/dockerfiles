# Postfix Docker Image

Docker container for [Postfix](http://www.postfix.org/) SMTP relay server.

## Usage

```bash
docker run -d \
  -p 25:25 \
  timjdfletcher/postfix
```

## Configuration

Mount custom Postfix configuration files:

```bash
docker run -d \
  -p 25:25 \
  -v /path/to/main.cf:/etc/postfix/main.cf:ro \
  -v /path/to/master.cf:/etc/postfix/master.cf:ro \
  timjdfletcher/postfix
```

## Common Relay Configuration

Example `main.cf` for a simple relay:

```ini
myhostname = mail.example.com
mydomain = example.com
myorigin = $mydomain
inet_interfaces = all
mydestination =
relayhost = [smtp.upstream.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
```

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 25 | TCP | SMTP |

## Build

```bash
./run build
```

## Test

```bash
./run test
```

Runs rspec tests (requires Ruby and Bundler).
