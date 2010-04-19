require 'bcsec'

module Bcsec
  ##
  # Common code for dealing with CAS servers.
  #
  # @see Bcsec::Modes::Cas
  # @see Bcsec::Authorities::Cas
  module Cas
    autoload :ConfigurationHelper, 'bcsec/cas/configuration_helper'
  end
end