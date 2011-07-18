require 'active_record'
require 'bcdatabase'
require 'database_cleaner'

module Aker
  module Spec
    module DatabaseConfiguration
      PARAMS = {
        'test' => [:local_oracle, :cc_pers_test],
        'ci_1.8.7' => [:bcdev, :cc_pers_hudson_aker],
        'ci_1.9'   => [:bcdev, :cc_pers_hudson_aker_yarv],
        'ci_jruby' => [:bcdev, :cc_pers_hudson_aker_java]
      }

      class << self
        def env
          ENV['AKER_ENV'] || 'test'
        end

        def active_record_configuration
          @configuration ||= Bcdatabase.load[*params]
        end

        def connect!
          ActiveRecord::Base.establish_connection(active_record_configuration)
          ActiveRecord::Base.schemas = { :cc_pers => params.last }
        end

        def connect_if_necessary
          connect! unless ActiveRecord::Base.connected?
        end

        private

        def params
          PARAMS[env]
        end
      end
    end

    class DatabaseData
      def self.use_in(spec_config)
        spec_config.include(UseDatabaseData)

        spec_config.after(:each) do
          if @use_database_data
            @database_data.after_each
          end
        end
      end

      def self.prepare
        # Use a process-level singleton in order to cache the loaded
        # yaml files.
        @instance ||= self.new
      end

      def initialize
        DatabaseConfiguration.connect_if_necessary
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with(:truncation)
      end

      def before_each
        DatabaseConfiguration.connect_if_necessary
        DatabaseCleaner.start
        insert_test_data
      end

      def after_each
        DatabaseCleaner.clean
      end

      def table_contents
        load_data_files unless @table_contents
        @table_contents
      end

      private

      def conn
        ActiveRecord::Base.connection
      end

      def load_data_files
        @table_contents = { }
        Dir["#{File.dirname(__FILE__)}/fixtures/*.yml"].each do |fn|
          table = File.basename(fn).sub /\.ya?ml/, ''
          @table_contents[table] = { :rows => File.open(fn) { |f| YAML.load(f) }.values }
          @table_contents[table][:inserts] =
            @table_contents[table][:rows].collect { |row|
              build_insert(table, row)
            }
        end
      end

      def insert_test_data
        table_contents.each do |table, contents|
          contents[:inserts].each do |stmt|
            conn.insert(stmt)
          end
        end
      end

      def build_insert(table, row)
        columns = row.keys
        "INSERT INTO #{table} (#{columns.join(", ")}) " <<
          "VALUES (#{columns.collect { |c| quote_value row[c] }.join(", ") })"
      end

      def quote_value(value_entry)
        if Hash === value_entry && value_entry["sql"]
          value_entry["sql"]
        else
          "'#{value_entry}'"
        end
      end
    end

    module UseDatabaseData
      def use_database
        @use_database_data = true
        @database_data = DatabaseData.prepare
        @database_data.before_each
      end
    end
  end
end
