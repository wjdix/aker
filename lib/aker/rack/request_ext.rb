require 'aker'

module Aker::Rack
  ##
  # Extensions for `Rack::Request`.
  #
  # To use these, `include` them into `Rack::Request`.
  module RequestExt
    include Aker::Rack::EnvironmentHelper

    ##
    # Whether the current request is interactive.
    #
    # @return [Boolean]
    def interactive?
      super(env)
    end
  end
end
