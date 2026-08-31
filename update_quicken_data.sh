#!/bin/bash

FILE=~/20260630.quicken.csv

KUBECTL='/snap/bin/kubectl'
POD="$("$KUBECTL" get pods -n postgres -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')"
"$KUBECTL" cp "$FILE" "postgres/${POD}:/tmp/transactions.csv"
"$KUBECTL" exec -n postgres "${POD}" -- chmod 666 /tmp/transactions.csv
"$KUBECTL" exec -n postgres "${POD}" -- psql -U bobb -h localhost -d money -c "truncate quicken_data"
"$KUBECTL" exec -n postgres "${POD}" -- psql -U bobb -h localhost -d money -c "copy quicken_data from '/tmp/transactions.csv' header csv"
"$KUBECTL" exec -n postgres "${POD}" -- rm /tmp/transactions.csv

