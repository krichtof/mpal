#!/bin/sh
start_time=$(date +%s)

command=scalingo
version=$($command -v)
if [ $? -ne 0 ]; then
  echo "You must install scalingo CLI: http://cli.scalingo.com"
  exit 1
fi

env=$1
if [ -z "$env" ]; then
  echo "Usage: $0 <env>"
  echo "Env must be: 'production', 'demo' or 'staging'."
  exit 2
fi

echo "Opening the tunnel…"
$command -a anah-$env db-tunnel SCALINGO_POSTGRESQL_URL

