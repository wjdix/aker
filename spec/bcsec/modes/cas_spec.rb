require File.expand_path("../../../spec_helper", __FILE__)
require File.expand_path("a_bcsec_mode", File.dirname(__FILE__))
require 'rack'
require 'uri'

module Bcsec::Modes
  describe Cas do
    before do
      @env = ::Rack::MockRequest.env_for('/')
      @scope = mock
      @mode = Cas.new(@env, @scope)
    end

    it_should_behave_like "a bcsec mode"

    describe "#key" do
      it "is :cas" do
        Cas.key.should == :cas
      end
    end

    describe "#valid?" do
      it "returns false if the ST parameter is not in the query string" do
        @mode.should_not be_valid
      end

      it "returns true if the ticket parameter is in the query string" do
        @env['QUERY_STRING'] = 'ticket=ST-1foo'

        @mode.should be_valid
      end
    end

    describe "#kind" do
      it "is :cas" do
        @mode.kind.should == :cas
      end
    end

    describe "#credentials" do
      it "returns the service ticket" do
        @env["QUERY_STRING"] = "ticket=ST-1foo"

        @mode.credentials.should == ["ST-1foo"]
      end

      it "returns an empty array if no service ticket was supplied" do
        @mode.credentials.should == []
      end
    end

    describe "#authenticate!" do
      before do
        @authority = mock
        @env['bcsec.authority'] = @authority
        @env['QUERY_STRING'] = 'ticket=ST-1foo'
      end

      it "signals success if the service ticket is good" do
        user = stub
        @authority.should_receive(:valid_credentials?).with(:cas, 'ST-1foo').and_return(user)
        @mode.should_receive(:success!).with(user)

        @mode.authenticate!
      end

      it "does not signal success if the service ticket is bad" do
        @authority.stub!(:valid_credentials? => nil)
        @mode.should_not_receive(:success!)

        @mode.authenticate!
      end
    end

    describe "#on_ui_failure" do
      before do
        @env['bcsec.configuration'] = Bcsec::Configuration.new do
          cas_parameters :login_url => 'https://cas.example.edu/login'
        end
      end

      it "redirects to the CAS server's login page" do
        response = @mode.on_ui_failure
        location = URI.parse(response.location)
        response.should be_redirect

        location.scheme.should == "https"
        location.host.should == "cas.example.edu"
        location.path.should == "/login"
      end

      def actual_uri
        response = @mode.on_ui_failure
        URI.parse(response.location)
      end

      describe "service URL" do
        it "is the user was trying to reach" do
          @env["PATH_INFO"] = "/foo/bar"

          actual_uri.query.should == "service=http://example.org/foo/bar"
        end

        it "is warden's 'attempted path' if present" do
          @env["PATH_INFO"] = "/unauthenticated"
          @env["warden.options"] = { :attempted_path => "/foo/quux" }

          actual_uri.query.should == "service=http://example.org/foo/quux"
        end

        it "includes the port if not the default for http" do
          @env["warden.options"] = { :attempted_path => "/foo/quux" }
          @env["rack.url_scheme"] = "http"
          @env["SERVER_PORT"] = 81

          actual_uri.query.should == "service=http://example.org:81/foo/quux"
        end

        it "includes the port if not the default for https" do
          @env["warden.options"] = { :attempted_path => "/foo/quux" }
          @env["rack.url_scheme"] = "https"
          @env["SERVER_PORT"] = 80

          actual_uri.query.should == "service=https://example.org:80/foo/quux"
        end
      end
    end
  end
end
