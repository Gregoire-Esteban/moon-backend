# Dockerfile for the proxy image (based on nginx 1.30.6-alpine3.24-slim) wrapped with its configuration
FROM nginx@sha256:e2355aa95529a7999dad94ddcb45a8768abf6fb0b204c93b1a3ffce477d7b893
COPY --chmod=644 default.conf /etc/nginx/conf.d/default.conf
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/cache/nginx /var/run/nginx.pid
USER nginx
# Start nginx with a delay of 3 seconds
ENTRYPOINT ["/bin/sh", "-c", "sleep ${NGINX_STARTUP_DELAY:-3} && exec /docker-entrypoint.sh nginx -g 'daemon off;'"]