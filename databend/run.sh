#!/bin/bash

TRIES=3
QUERY_NUM=1
cat queries.sql | while read -r query; do
    [ -z "$FQDN" ] && sync
    [ -z "$FQDN" ] && echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null

    echo -n "["
    for i in $(seq 1 $TRIES); do
        BODY=$(mktemp)
        STATS=$(curl -sS -o "$BODY" -w 'HTTP:%{http_code} TIME:%{time_total}\n' "http://default@localhost:8124" -d "${query}" 2>&1)
        CURL_EXIT=$?
        HTTP_CODE=$(echo "$STATS" | grep -oP 'HTTP:\K[0-9]+')
        RES=$(echo "$STATS" | grep -oP 'TIME:\K[0-9.]+')

        if [[ "$CURL_EXIT" == "0" && "$HTTP_CODE" == "200" && -n "${RES}" ]] && ! grep -qiE '"error"|exception|error code' "$BODY"
        then
            echo -n "${RES}"
        else
            echo -n "null"
            RES=""
        fi
        rm -f "$BODY"
        [[ "$i" != $TRIES ]] && echo -n ", "

        echo "${QUERY_NUM},${i},${RES}" >> result.csv
    done
    echo "],"

    QUERY_NUM=$((QUERY_NUM + 1))
done
