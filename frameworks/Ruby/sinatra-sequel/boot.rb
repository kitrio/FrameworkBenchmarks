# frozen_string_literal: true
require 'bundler/setup'
require 'time'

MAX_PK = 10_000
ID_RANGE = (1..MAX_PK).freeze
ALL_IDS = ID_RANGE.to_a
QUERIES_MIN = 1
QUERIES_MAX = 500
SEQUEL_NO_ASSOCIATIONS = true
SERVER_STRING = "Sinatra"

Bundler.require(:default) # Load core modules

def connect(dbtype)
  Bundler.require(dbtype) # Load database-specific modules

  adapters = {
    mysql: 'mysql2',
    postgresql: 'postgres'
  }

  opts = {}

  # Determine threading/thread pool size and timeout
  if defined?(Puma) && (threads = Puma.cli_config.options.fetch(:max_threads)) > 1
    opts[:max_connections] = (2 * Math.log(threads)).floor
    opts[:pool_timeout] = 10
  end

  Sequel.connect \
    '%{adapter}://%{host}/%{database}?user=%{user}&password=%{password}' % {
      adapter: (dbtype == :mysql ? 'mysql2' : 'postgresql'),
      host: 'tfb-database',
      database: 'hello_world',
      user: 'benchmarkdbuser',
      password: 'benchmarkdbpass'
    }, opts
end

DB = connect ENV.fetch('DBTYPE').to_sym

# Define ORM models
class World < Sequel::Model(:World)
  def_column_alias(:randomnumber, :randomNumber) if DB.database_type == :mysql

  def self.batch_update(worlds)
    if DB.database_type == :mysql
      worlds.map(&:save_changes)
    else
      ids = []
      sql = String.new("UPDATE world SET randomnumber = CASE id ")
      worlds.each do |world|
        sql << "when #{world.id} then #{world.randomnumber} "
        ids << world.id
      end
      sql << "ELSE randomnumber END WHERE id IN ( #{ids.join(',')})"
      DB.run(sql)
    end
  end
end

class Fortune < Sequel::Model(:Fortune)
  # Allow setting id to zero (0) per benchmark requirements
  unrestrict_primary_key
end

[World, Fortune].each(&:freeze)
DB.freeze
