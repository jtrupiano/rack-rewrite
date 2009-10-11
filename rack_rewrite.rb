module Rack
  class Rewrite
    def initialize(app, &rule_block)
      @app = app
      @rule_set = RuleSet.new
      @rule_set.instance_eval(&rule_block) if block_given?
    end
    
    def call(env)
      if matched_rule = find_rule(env)
        apply(matched_rule, env)
      else
        @app.call(env)
      end
    end
    
    # This logic needs to be pushed into Rule subclasses
    def apply(rule, env)
      case rule[0]
      when :r301
        [301, {'Location' => rule[2]}, ['Redirecting...']]
      when :r302
        [302, {'Location' => rule[2]}, ['Redirecting...']]
      when :rewrite
        # return [200, {}, {:content => env.inspect}]
        env['PATH_INFO'] = env['REQUEST_URI'] = rule[2]
        @app.call(env)
      else
        raise Exception.new("Unsupported rule: #{rule[0]}")
      end
    end
    
    # This will probably have to changeas rule matching gets more complicated
    def find_rule(env)
      @rule_set.rules.detect { |rule| rule[1] == env['PATH_INFO'] }
    end
    
    class RuleSet
      
      attr_reader :rules
      def initialize
        @rules = []
      end
      
      private
        # We're explicitly defining the functions for our DSL rather than using
        # method_missing
        %w(rewrite r301 r302).each do |meth|
          define_method(meth) do |from, to|
            @rules << [meth.to_sym, from, to]
          end
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

    def call_args(overrides={})
      {'PATH_INFO' => '/wiki/Yair_Flicker'}.merge(overrides)
    end
    
    def self.should_not_halt
      should "not halt the rack chain" do
        @app.expects(:call).once
        @rack.call(call_args)
      end
    end
    
    def self.should_be_a_rack_response
      should 'be a rack a response' do
        ret = @rack.call(call_args)
        assert ret.is_a?(Array), 'return value is not a valid rack response'
        assert_equal 3, ret.size, 'should have 3 arguments'
      end
    end
    
    def self.should_halt
      should "should halt the rack chain" do
        @app.expects(:call).never
        @rack.call(call_args)
      end
      should_be_a_rack_response
    end
        
    def self.should_location_redirect_to(location, code)
      should "respond with http status code #{code}" do
        ret = @rack.call(call_args)
        assert_equal code, ret[0]
      end
      should 'send a location header' do
        ret = @rack.call(call_args)
        assert_equal location, ret[1]['Location'], 'Location is incorrect'
      end
    end
    
    context 'Given an app' do
      setup do
        @app = Class.new { def call; true; end }.new
      end
    
      context 'when no rewrite rule matches' do
        setup {
          @rack = Rack::Rewrite.new(@app)
        }
        should_not_halt
      end
      
      context 'when a 301 rule matches' do
        setup {
          @rack = Rack::Rewrite.new(@app) do
            r301 '/wiki/Yair_Flicker', '/yair'
          end
        }
        should_halt
        should_location_redirect_to('/yair', 301)
      end
      
      context 'when a 302 rule matches' do
        setup {
          @rack = Rack::Rewrite.new(@app) do
            r302 '/wiki/Yair_Flicker', '/yair'
          end
        }
        should_halt
        should_location_redirect_to('/yair', 302)
      end
      
      context 'when a rewrite rule matches' do
        setup {
          @rack = Rack::Rewrite.new(@app) do
            rewrite '/wiki/Yair_Flicker', '/john'
          end
        }
        should_not_halt
        should "set PATH_INFO and REQUEST_URI to '/john'" do
          @app.expects(:call).with(call_args.merge({'PATH_INFO' => '/john', 'REQUEST_URI' => '/john'})).once
          @rack.call(call_args)
        end
      end
    end
  end
end