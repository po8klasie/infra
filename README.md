# WarsawLO Infra

Infra for WarsawLO.

Goals:
* Minimum cost
* Minimum maintenance
* Survive big spikes in traffic
* Automated deploys, at least to the test instance
* Currently stateless, but has to be able to support statefulness (only in db) in the future

Non goals:
* Automated bootstrapping: initial setup won't happen that often
* **Automated updates of infra code (they don't happen often)**

## Architecture Overview

![Architecture Diagram](WarsawLO%20Architecture.png)

Life of a request:
1. If it's in Cloudflare cache it gets server from there.
2. If not, it is passed (via HTTP, in our setup Cloudflare strips SSL) to the gcp instance external IP port 80.
3. Inside the instance it's routed to the nginx container.
4. If the path is not `/django/*` it gets served directly from the nginx container.
5. Otherwise nginx converts the request to the uWSGI protocol and passes it to the uWSGI container.
6. The result is served to the client and saved in Cloudflare cache.

Components:
* Nginx image: [warsawlo/warsawlo-2.0](https://hub.docker.com/r/warsawlo/warsawlo-2.0), built from https://github.com/warsawLO/warsawlo-2.0
* uWSGI image: [warsawlo/warsawlo-django](https://hub.docker.com/r/warsawlo/warsawlo-django), build from https://github.com/WarsawLO/warsawlo-django

### CI
* Images are automatically built and uploaded to docker hub using GitHub Actions.
* The same action handles pulling and restarting containers on the test deployment +
  cloudflare cache purge.

## Detailed setup

### Google Cloud
* Create an `f1-micro` instance (go to "Compute Engine")
    * We suggest `europe-west4`: cheaper than Frankfurt, still pretty good latency.
    * OS image: latest stable of Container Optimized OS (10GB is fine)
    * Select "Allow HTTP traffic"
* Log into the instance by clicking the "SSH" button.
    * Open port 80: `sudo iptables -w -A INPUT -p tcp --dport 80 -j ACCEPT`
    * `git pull https://github.com/WarsawLO/infra`
    * `cd infra`
    * `docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:$PWD" -w="$PWD" docker/compose:1.25.5 up -d`
    * To see logs: `docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:$PWD" -w="$PWD" docker/compose:1.25.5 logs -f`. You can safely Ctrl-C this command, it won't stop any contaienrs.
    * To update:
        * `docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:$PWD" -w="$PWD" docker/compose:1.25.5 pull`
        * `docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:$PWD" -w="$PWD" docker/compose:1.25.5 up -d`
* Create a service account, download the json key, set is as `GCE_SA_KEY` secret in github. Add
  IAM roles: `Compute OS Admin Login` and `Service Account User`.
* Create an API token with permissions `Zone.Cache Purge`, save as `CLOUDFLARE_TOKEN` secret.
* The rest of the secrets are self explanatory.

### Cloudflare
* DNS -> pick a (sub)domain that points to the gcp instance external IP. Proxy status "Proxied"
* SSL/TLS
    * Overview tab
        * Flexible
    * Edge Certificates tab
        * Always Use HTTPS -> On
        * HSTS
            * Enable -> On
            * max-age -> 12 months
            * includeSubDomains -> On
            * Preload -> On
            * No-Sniff Header -> On
        * Minimum TLS Version -> TLS 1.2
        * Opportunistic Encryption -> Off
        * TLS 1.3 -> On
        * Automatic HTTPS Rewrites -> On
        * Certificate Transparency Monitoring -> On
* Caching
    * Cachin Level -> Standard
    * Browser Cache TTL -> Respect Existing Headers
    * Always Online -> On
* Page Rules
    * `{your domain}/*`
        * Cache Level -> Cache Everything
        * Edge Cache TTL -> a month
* Network
    * HTTP/3 (with QUIC) -> On
    * 0-RTT Connection Resumption -> On
    * WebSockets -> Off
* Scrape Shield -> Yours to choose
