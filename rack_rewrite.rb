module Rack
  class Rewrite
    def initialize(app, options={})
      @app, @options = app, options
      @rules = options.fetch(:rules, {})
    end
    
    def call(env)
      if matched_rule = @rules.keys.detect {|str| str == env['PATH_INFO']}
        [301, {'Location' => @rules[matched_rule]}, ['Redirecting...']]
      else
        @app.call(env)
      end
    end
  end
end

if __FILE__ == $0
  require 'test/unit'
  require 'rubygems'
  gem 'shoulda', '~> 2.10.2'
  require 'shoulda'
  gem 'mocha', '~> 0.9.7'
  require 'mocha'
  
  class RackRewriteTest < Test::Unit::TestCase

    def call_args
      {'PATH_INFO' => '/wiki/Yair_Flicker'}
    end
    
    def self.should_return_a_301_to(&block)
      should "return a 301" do
        @app.expects(:call).never
        ret = @rack.call(call_args)
        assert ret.is_a?(Array), 'return value is not a valid rack response'
        assert_equal 301, ret[0]
        assert_equal block.call, ret[1]['Location'], 'Location is incorrect'
      end
    end
    
    def self.should_pass_through_to_app
      should "pass through to app" do
        @app.expects(:call).with(call_args).once
        assert true === @rack.call(call_args), "our mock response is supposed to be true"
      end
    end
    
    context 'Given an app' do
      
      setup do
        @app = Class.new { def call; true; end }.new
      end
    
      context 'when no rewrite rules match ' do
        setup do
          @rack = Rack::Rewrite.new(@app)
        end
      
        should_pass_through_to_app
      end
      
      context 'when a 301 rewrite rule matches' do
        setup do
          @rack = Rack::Rewrite.new(@app, :rules => {
            "/wiki/Yair_Flicker" => "/yair"
          })
        end
        
        should_return_a_301_to { '/yair' }
      end
    end
  end
end