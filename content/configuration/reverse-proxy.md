---
title: Reverse Proxy Setup
---

It is possible to put Humio behind a proxy server. You can use any
reverse proxy you want, as long as it can keep the connection from the
browser to Humio "Sticky" towards the same Humio node, at least as
long as that node is alive if you have multiple Humio nodes in a
clustered setup.

{{% notice warning %}}
It is important that the proxy does not rewrite urls, when forwarding to Humio.
{{% /notice %}}

## Example setup using nginx

For this example the proxy server will accept all request at `http://example.com`
and expose Humio on `http://example.com/internal/humio/`.

For this to work, the proxy must be set up to forward incoming requests with a
location starting with `/internal/humio` to the Humio server and
Humio must be configured with a proxy prefix url `/internal/humio`. This is done
by letting the proxy add the header `X-Forwarded-Prefix`.

Humio requires the proxy to add the header `X-Forwarded-Prefix` only when Humio
is hosted at at a non-empty prefix.

Thus hosting Humio at "http://humio.example.com/" works without adding a header.
An example configuration snippet for an nginx location is:

```nginx
location /internal/humio {

    proxy_set_header        X-Forwarded-Prefix /internal/humio;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        Host $host;

    proxy_pass          http://localhost:8080;
    proxy_read_timeout  10;
    proxy_redirect http:// https://;
    expires off;
    proxy_http_version 1.1;
  }
```

If it is not feasible for you to add the header `X-Forwarded-Prefix` in your proxy,
there is a fall-back solution: You can set `PROXY_PREFIX_URL` in
your `/home/humio/humio-config.env`.

### Adding TLS to nginx using letsencrypt

If you turn on authentication in Humio we recommend that you also run
the Humio UI on TLS only and not on plain HTTP. This section shows an
example of how to add TLS to the nginx configuration above.

If you use a reverse proxy other than nginx, please refer to the
documentation for that proxy on how to enable TLS. The letsencrypt
parts here will likely be the same regardless of proxy, except perhaps
the command that need executing to get the proxy to reload the
certificate files

##### Making nginx use the certificate

The following snippet sets up nginx to use the certificate issued and
renewed above and tells nginx to use port 443 for TLS connections, and
port 80 for plain HTTP connections. It serves the files from the
"root" directory required by letsencrypt for validating the ownership
of the domains. On TLS all other requests are handled by the
"location" sections. On port 80 for plain HTTP, the config redirects
all requests that do not start with "." to TLS.


```nginx
ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;

ssl_protocols TLSv1.2;

server {
  ssl on;
  listen [::]:443;
  listen 443;
  server_name ${FQDN};

  # letsencrypt webroot:
  root /var/www/html;
  location ~ /.well-known {
    allow all;
  }
}

server {
  ssl off;
  listen [::]:80;
  listen 80;
  server_name ${FQDN};

  # letsencrypt webroot:
  root /var/www/html;
  location ~ /.well-known {
    allow all;
  }
  # Everything that does not start with ".", redir to https.
  location ~ /[^.] {
    return 301 https://\$server_name\$request_uri;
  }
}
```

Reload nginx
```shel
sudo systemctl reload nginx
```

##### Getting the initial certificate

Issue the certificate using letsencrypt. The letsencrypt servers must
be able to lookup the name in DNS and get in touch with the server
running the command for the process to succeed. (If this is not
possible for you, then see the letsencrypt documentation on how to
issue certificates using TXT records, or other means of obtaining
certificates)

```shell
sudo letsencrypt certonly -a webroot --webroot-path=/var/www/html -m "${YOUR_EMAIL}" --agree-tos --domains "${FQDN}"
```

##### Auto-renewal through letsencrypt
The following snippet sets up a crontab entry that checks if the certificate needs renewal and renews it if needed. If the certificate is renewed then nginx gets reloaded to use the new certificate.

```shell
cat << EOF > /etc/cron.weekly/humio-letsencrypt
#!/bin/sh
letsencrypt renew -a webroot --webroot-path=/var/www/html -m "${YOUR_EMAIL}" && systemctl reload nginx
EOF
chmod 755 /etc/cron.weekly/humio-letsencrypt
```

#### Adding TLS to nginx with a public cert

Added in the `http {` tag right above the closing `}`
```
        ##
        #Humio Snipets
        ##
        ssl_certificate /<PATH_TO_YOUR_CERT>/<CERT>.crt;
        ssl_certificate_key /<PATH_TO_YOUR_KEY>/<KEY>.pem;

        ssl_protocols TLSv1.2;

        server {
          ssl on;
          listen [::]:443;
          listen 443;
          server_name <PROTOCOL>://<YOUR_SERVERS_URL>;

          location / {
           proxy_set_header        X-Forwarded-Proto $scheme;
           proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header        X-Real-IP $remote_addr;
           proxy_set_header        Host $host;
          
           proxy_pass          http://localhost:8080;
           proxy_read_timeout  10;
           proxy_redirect http:// https://;
           expires off;
           proxy_http_version 1.1;
          }
         }
        ##
        #End Humio
        ##

```


#### nginx inside a docker container

The above examples assume that nginx was running as a plain
systemd-controlled on the host system. If you plan to run nginx inside
a docker container, nginx still needs to be able to read the
certificate files. Note that nginx needs to start as root inside the
container in order to read the mounted files.  The suggested solution
is to add

```
-v /etc/letsencrypt:/etc/letsencrypt:ro
```

to the docker run command, keeping letsencrypt outside the docker
container. We suggest this in order to not loose the files that
letsencrypt stores in `/etc/letsencrypt` as you have to start over and
issue from scratch if those files are lost. The renewal then needs to
restart the docker container instead:

```shell
cat << EOF > /etc/cron.weekly/humio-letsencrypt
#!/bin/sh
## Renewal for nginx wirh nginx inside a docker container:
letsencrypt renew -a webroot --webroot-path=/var/www/html -m "${YOUR_EMAIL}" && docker restart your-nginx-container
EOF
chmod 755 /etc/cron.weekly/humio-letsencrypt
```
