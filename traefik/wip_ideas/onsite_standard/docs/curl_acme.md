curl -v http://traefik.pocs.hachim.fr
* Host traefik.pocs.hachim.fr:80 was resolved.
* IPv6: (none)
* IPv4: 51.77.54.71
*   Trying 51.77.54.71:80...
* Connected to traefik.pocs.hachim.fr (51.77.54.71) port 80
> GET / HTTP/1.1
> Host: traefik.pocs.hachim.fr
> User-Agent: curl/8.7.1
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 404 Not Found
< Content-Type: text/plain; charset=utf-8
< X-Content-Type-Options: nosniff
< Date: Sun, 06 Apr 2025 08:32:23 GMT
< Content-Length: 19
<
404 page not found
* Connection #0 to host traefik.pocs.hachim.fr left intact