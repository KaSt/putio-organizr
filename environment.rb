$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), './app'))

$stdout.sync = true

require 'resque'
require 'sequel'

require_relative 'config/dependencies'
Import = Dry::AutoInject(Dependencies)

if ENV['MIGRATE_DB']
  Sequel.extension :migration
  Sequel::Migrator.run(Dependencies['db'], File.expand_path('../db/migrations', __FILE__))
end

Resque.redis = Dependencies[:redis]

require 'client'
require 'shows_repository'
require 'accounts_repository'
require 'tvshows'
require 'organizer'
require 'organizer_job'
