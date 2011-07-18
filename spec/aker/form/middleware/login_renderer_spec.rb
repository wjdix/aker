require File.expand_path("../../../../spec_helper", __FILE__)
require "rack/test"

module Aker::Form::Middleware
  describe LoginRenderer do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Aker::Form::Middleware::LoginRenderer, '/login'
        run lambda { |env| [200, {"Content-Type" => "text/html"}, ["Hello"]] }
      end
    end

    let(:env) do
      { 'aker.configuration' => configuration }
    end

    let(:configuration) { Aker::Configuration.new }

    it "does not intercept POSTs to the login path" do
      post "/login", {}, env

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    it "does not intercept GETs to paths that are not the login path" do
      get "/foo", {}, env

      last_response.should be_ok
      last_response.body.should == "Hello"
    end

    it "renders login forms for GETs on the login path" do
      get "/login", {}, env

      last_response.should be_ok
      last_response.content_type.should == "text/html"
    end

    it "outputs CSS for GETs on (the login path) + .css" do
      get "/login/login.css", {}, env

      last_response.should be_ok
      last_response.content_type.should == "text/css"
    end
  end
end
