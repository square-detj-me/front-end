This repo contains the front end of square.detj.me and (nearly) everything required to host it

* Elm Code for the web app - `/elm/src`
* Generated data file for every country - `/elm/html/data/countries.json`
* Images for every country - `/elm/html/images/*`
* docker-compose config that spins up an nginx image - `/docker-compose.yaml`
* nginx config for hosting the website - `/nginx/nginx.conf`
* A script for renewing the site's SSL certs via a certbox docker image - `/renew-certs.sh`