#!/usr/bin/env bash

# set -x

# echo "arg 1 $1"


BASE_DIR=/usr/share/nginx/html
NGINX_CONF=/etc/nginx/nginx.conf
DEFAULT_CONF=/etc/nginx/conf.d/default.conf

dedupe_nginx_events_block() {
    # Keep only the first events{} block in the main nginx config.
    # If another process/image layer injected a duplicate block, nginx fails hard.
    awk '
    BEGIN { in_dup=0; depth=0; seen_events=0 }
    {
        if (!in_dup && $0 ~ /^[[:space:]]*events[[:space:]]*\{[[:space:]]*$/) {
            seen_events++
            if (seen_events > 1) {
                in_dup=1
                depth=1
                next
            }
        }
        if (in_dup) {
            open_count = gsub(/\{/, "{")
            close_count = gsub(/\}/, "}")
            depth += (open_count - close_count)
            if (depth <= 0) {
                in_dup=0
            }
            next
        }
        print
    }' "$NGINX_CONF" > /tmp/nginx.conf
    mv /tmp/nginx.conf "$NGINX_CONF"
}

if [ -n "$1" ]
then
    exec "$@"
fi

if [ -n "$INSTANA_EUM_KEY" -a -n "$INSTANA_EUM_REPORTING_URL" ]
then
    echo "Enabling Instana EUM"
    result=$(curl -kv -s --connect-timeout 10 "$INSTANA_EUM_REPORTING_URL" 2>&1 | grep "301 Moved Permanently")
    if [ -n "$result" ]; 
    then
        echo '301 Moved Permanently found!'
        [[ "${INSTANA_EUM_REPORTING_URL}" != */ ]] &&  INSTANA_EUM_REPORTING_URL="${INSTANA_EUM_REPORTING_URL}/"
        sed -i "s|INSTANA_EUM_KEY|$INSTANA_EUM_KEY|" $BASE_DIR/eum-tmpl.html
        sed -i "s|INSTANA_EUM_REPORTING_URL|$INSTANA_EUM_REPORTING_URL|" $BASE_DIR/eum-tmpl.html
        cp $BASE_DIR/eum-tmpl.html $BASE_DIR/eum.html
    else
        echo "Go with the user input"
        sed -i "s|INSTANA_EUM_KEY|$INSTANA_EUM_KEY|" $BASE_DIR/eum-tmpl.html
        sed -i "s|INSTANA_EUM_REPORTING_URL|$INSTANA_EUM_REPORTING_URL|" $BASE_DIR/eum-tmpl.html
        cp $BASE_DIR/eum-tmpl.html $BASE_DIR/eum.html
    fi

else
    echo "EUM not enabled"
    cp $BASE_DIR/empty.html $BASE_DIR/eum.html
fi

# make sure nginx can access the eum file
chmod 644 $BASE_DIR/eum.html

# apply environment variables to default.conf
envsubst '${CATALOGUE_HOST} ${USER_HOST} ${CART_HOST} ${SHIPPING_HOST} ${PAYMENT_HOST} ${RATINGS_HOST}' < /etc/nginx/conf.d/default.conf.template > "$DEFAULT_CONF"

if [ -f /tmp/ngx_http_opentracing_module.so -a -f /tmp/libinstana_sensor.so ]
then
    echo "Patching for Instana tracing"
    mv /tmp/ngx_http_opentracing_module.so /usr/lib/nginx/modules
    mv /tmp/libinstana_sensor.so /usr/local/lib
    if ! grep -q "Instana tracing bootstrap" "$NGINX_CONF"; then
    cat - "$NGINX_CONF" << !EOF! > /tmp/nginx.conf
# Extra configuration for Instana tracing
# Instana tracing bootstrap
load_module modules/ngx_http_opentracing_module.so;

# Pass through these env vars
env INSTANA_SERVICE_NAME;
env INSTANA_AGENT_HOST;
env INSTANA_AGENT_PORT;
env INSTANA_MAX_BUFFERED_SPANS;
env INSTANA_DEV;
!EOF!

    mv /tmp/nginx.conf "$NGINX_CONF"
    fi
    echo "{}" > /etc/instana-config.json
else
    echo "Tracing not enabled"
    # remove tracing config
    sed -i '1,3d' "$DEFAULT_CONF"
fi

dedupe_nginx_events_block

if ! nginx -t; then
    echo "nginx config test failed"
    exit 1
fi

exec nginx-debug -g "daemon off;"

