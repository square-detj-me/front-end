# To be ran as a cron job once per day

docker run -it --rm \
-v /opt/square/letsencrypt/config:/etc/letsencrypt \
-v /opt/square/letsencrypt/work:/var/lib/letsencrypt \
-v /opt/square/letsencrypt/html:/data/letsencrypt \
-v "/opt/square/letsencrypt/log:/var/log/letsencrypt" \
certbot/certbot \
renew --webroot \
-w /data/letsencrypt \
--email **CENSORED** --agree-tos \
--webroot-path=/data/letsencrypt