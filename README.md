# WarsawLO Infra

Infra for WarsawLO.

Goals:
* Minimum cost
* Minimum maintenance
* Survive big spikes in traffic
* Automated deploys, at least to the test instance [WIP]
* Currently stateless, but has to be able to support statefulness (only in db) in the future

Non goals:
* Automated bootstrapping: initial setup won't happen that often

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
* [WIP] A cron job on the gcp machine pulls new images and recreates containers every `n` minutes.
