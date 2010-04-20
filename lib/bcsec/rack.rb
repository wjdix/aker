require 'bcsec'
require 'warden'

##
# Integration of Bcsec with {http://rack.rubyforge.org/ Rack}.
module Bcsec::Rack
  class << self
    ##
    # Configures all the necessary middleware for Bcsec into the given
    # rack application stack.  With `Rack::Builder`:
    #
    #      Rack::Builder.new do |builder|
    #        Bcsec::Rack.use_in(builder)
    #      end
    #
    # Bcsec's middleware stack relies on the existence of a session,
    # so the session-enabling middleware must be higher in the
    # application stack than Bcsec.
    #
    # @param [#use] builder the target application builder.  This
    #   could be a `Rack::Builder` object or something that acts like
    #   one.
    # @return [void]
    def use_in(builder)
      install_modes

      builder.use Warden::Manager
    end

    private

    ##
    # @return [void]
    def install_modes
      Bcsec::Modes.constants.
        collect { |s| Bcsec::Modes.const_get(s) }.
        select { |c| c.respond_to?(:key) }.
        each do |mode|
        Warden::Strategies.add(mode.key, mode)
      end
    end
  end
end