#!/bin/bash

set -euf -o pipefail

if [ "$1" == "vaccination" ]; then
  deploy_dir='vaccination-form-backend'
  passenger_app_name='vaccination_form'
else
  deploy_dir='covid-form-backend'
  passenger_app_name='covid_form'
fi

if [ -n "${2-}" ]; then
  servers=("$2")
else
  servers=(production1-tth production2-tth)
fi

env_file='.env'
deploy_to="deploy/spital/$deploy_dir"

echo "deploying to $deploy_to"

for server in ${servers[@]}; do
  echo "deploying to $server"
  ssh -T $server <<EOF
    cd $deploy_to
    git pull
    bundle install
    load-dotenv $env_file
    rake db:migrate
    load-dotenv $env_file.passwords
    rake db:migrate_passwords
    passenger-config restart-app --name $passenger_app_name || true
EOF
done
