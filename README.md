# Installation

* install PostgreSQL

```sh
apt install postgresql-server libpq-dev
```

* clone the repo

```sh
git clone Incanus3/covid-form-backend
```

* install rbenv and rbenv-gemset (optional - you can install ruby any other way)

```sh
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
git clone git://github.com/jf/rbenv-gemset.git $HOME/.rbenv/plugins/rbenv-gemset
```

* install ruby

```sh
rbenv install 2.7.1
```

* select ruby and gemset

```sh
cd covid-form-backend
rbenv local 2.7.1
rbenv gemset init covid
```

* install dependencies

```sh
bundle install
```

# Development

* create db user and database

```sh
sudo -u postgres -i
postgres> createuser -P covid
postgres> createdb -O covid covid
# press ctrl+d to log out of postgres account
```

* if you use different database engine/host/user/port/..., set environment variables accordingly
  (see https://github.com/Incanus3/covid-form-backend/blob/master/app/dependencies.rb#L5)
* run database migrations

```sh
rake db:migrate
```

* run server in one terminal through rerun - it will restart the server on file changes

```sh
rerun -- bundle exec falcon serve -b http://localhost:9292
```

* run guard in another - it will watch for file changes and run tests and code style checker
  after each change (ignore the initial 'no cmd option specified' error)

```sh
bundle exec guard
```

# Production

* create db user and database
* run db migrations
* run facon server directly

```sh
bundle exec falcon serve -b http://0.0.0.0:80
```

* or run the app using any other server that supports rack apps
  (puma, thin, phusion passenger, whatever, see https://github.com/rack/rack)
* if you serve more than one app on the server, you can bind it to a different port and employ
  a reverse proxy (typically nginx) to forward traffic to each app (typically based on Host header)
* you can also use Phusion Passenger apache/nginx module to run the app in an nginx worker
  process(es)
* ideally set up SSL to transfer data securely over HTTPS
  (out of the scope of this Readme, see e.g. https://certbot.eff.org/)
