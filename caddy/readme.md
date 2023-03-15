# Recipe: Caddy

I have a Caddy http block listen on :3000 which I exposed in the Dockerfile previously, the block’s root for files is /var/www/html. I have also enabled minify and gzip extensions for the website, so far so good.

I also have setup a response header that caches assets (header /js /css /images Cache-Control "max-age=2592000"). There are also 3 other headers added to the response for security reasons.

Next up we have request logs: log / stdout "{>Cf-Connecting-Ip} - [{when}] \"{method} {uri} {proto}\" {status} {size} \"{>Referer}\" \"{>User-Agent}\"" The server I run this on is behind cloudflare, cloudflare is a sort of proxy, because of that I never see the source address in the right place, instead its in the Cf-Connecting-Ip header, thus I had to update output format to use that http header instead.

Finally there is the git extension block (git github.com/zet4/zeta.pm /var/www/app), when the server is first started it will pull the git repository of the website and put it into /var/www/app. It will also start listening to a webhook (hook /webhook secret_here).

Both on start and properly authenticated webhook request the server will first call git submodule update --init --recursive followed by then hugo -v --destination=/var/www/html, which will first pull submodules (the theme of the blog is a submodule) and then build the website to the directory.


#### References
* [](https://zeta.pm/blog/building-this-blog/)


Best caddy container:
* [caddybox](https://github.com/joshix/caddybox/)

**Latest:** I would suggest a separate Hugo job that downloads the code from Github and builds the site into some shared storage and the Caddy server to server the content (using caddybox above).  This could be put behind a Traefik load balancer/ingress.
