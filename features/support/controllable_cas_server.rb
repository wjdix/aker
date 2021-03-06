require 'rack/builder'
require 'yaml'
require 'fileutils'
require 'active_record' # see below
require File.expand_path("../controllable_rack_server.rb", __FILE__)

# Because rubycas-server's config.ru refers to the Rack module, it
# needs to be interpreted outside of the Aker module.
module CASServer
  def self.app(config_filename)
    ENV['CONFIG_FILE'] = config_filename

    rackup = File.expand_path("../config.ru",
                              $LOAD_PATH.detect { |path| path =~ /rubycas-server/ })

    ::Rack::Builder.parse_file(rackup).first
  end
end

module Aker
  module Cucumber
    class ControllableCasServer < ControllableRackServer
      include FileUtils

      attr_reader :users_database_filename

      def initialize(tmpdir, port)
        super(:port => port, :tmpdir => tmpdir, :ssl => true, :app_creator => lambda {
                CASServer.app(create_server_config(binding))
              })
      end

      def start
        @users_database_filename = create_user_database
        super
      end

      def stop
        PrivateModel.connection_handler.clear_all_connections!
        super
      end

      def register_user(username, password)
        PrivateModel.connection.
          update("INSERT INTO users (username, password) VALUES ('#{username}', '#{password}')")
      end

      protected

      def log_filename
        "cas-out.log"
      end

      private

      def active_record_adapter
        (RUBY_PLATFORM == 'java' ? 'jdbcsqlite3' : 'sqlite3')
      end

      def create_user_database
        File.join(tmpdir, 'cas-users.db').tap do |fn|
          rm fn if File.exist?(fn)
          PrivateModel.establish_connection :database => fn, :adapter => active_record_adapter
          PrivateModel.connection.update("CREATE TABLE users (username, password)")
        end
      end

      def create_server_config(scope)
        File.join(tmpdir, 'cas-config.yml').tap do |fn|
          File.open(fn, 'w') do |f|
            f.write(ERB.new(File.read(File.expand_path("../casserver.yml.erb", __FILE__))).
              result(scope))
          end
        end
      end

      # This class is used to provide an isolated point to use to
      # build the connection to the user database.  This hack is
      # required because jdbc-sqlite3 is wholly undocumented, so I
      # can't do JRuby compat without using an AR connection.
      class PrivateModel < ActiveRecord::Base
      end
    end
  end
end
