require 'sequel'

DB = Sequel.connect(
  adapter:  ENV.fetch('DB_BACKEND',  'postgres'),
  host:     ENV.fetch('DB_HOST',     'localhost'),
  port:     ENV.fetch('DB_PORT',     '5432'),
  user:     ENV.fetch('DB_USER',     'covid'),
  password: ENV.fetch('DB_PASSWORD', 'covid'),
  database: ENV.fetch('DB_NAME',     'covid'),
)
