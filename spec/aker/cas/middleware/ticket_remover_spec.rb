require File.expand_path("../../../../spec_helper", __FILE__)
require "rack/test"

module Aker::Cas::Middleware
  describe TicketRemover do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use Aker::Cas::Middleware::TicketRemover
        run lambda { |env| [404, { "Content-Type" => "text/plain" }, ['Requested content']] }
      end
    end

    let(:env) do
      { }
    end

    describe '#call' do
      it 'does nothing if not authenticated' do
        get '/foo?ticket=ST-45&q=bar', {}, env

        last_response.body.should == 'Requested content'
      end

      it 'does nothing if no ticket is present' do
        get '/foo?q=bar', {}, env

        last_response.body.should == 'Requested content'
      end

      context 'ticket is present and the user is authenticated' do
        before do
          env['aker.check'] = Aker::Rack::Facade.new(Aker.configuration, Aker::User.new('jo'))

          get '/foo?ticket=ST-45&q=bar', {}, env
        end

        it 'sends a permanent redirect' do
          last_response.status.should == 301
        end

        it 'redirects to the same URI without the ticket' do
          last_response.headers['Location'].should == 'http://example.org/foo?q=bar'
        end

        describe 'entity body' do
          it 'is presented as text/html' do
            last_response.headers['Content-Type'].should == 'text/html'
          end

          it 'has a link to the cleaned URI' do
            last_response.body.should == %q{<a href="http://example.org/foo?q=bar">Click here to continue</a>}
          end
        end
      end
    end
  end
end
