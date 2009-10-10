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
      when :'301'
        [301, {'Location' => rule[2]}, ['Redirecting...']]
      when :rewrite
        @app.call(env.merge({'PATH_INFO' => rule[2]}))
      end
    end
    
    def find_rule(env)
      puts "Looking for #{env['PATH_INFO']}"
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
        def rewrite(from, to)
          puts "Adding rewrite from #{from} to #{to}"
          @rules << [:rewrite, from, to]
        end
        
        # ugh
        define_method(:'301') do |from, to|
          @rules << [:'301', from, to]
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
    
    def self.should_return_a_301_to(&block)
      should "return a 301" do
        @app.expects(:call).never
        ret = @rack.call(call_args)
        assert ret.is_a?(Array), 'return value is not a valid rack response'
        assert_equal 301, ret[0]
        assert_equal block.call, ret[1]['Location'], 'Location is incorrect'
      end
    end
    
    def self.should_pass_through_to_app(headers={})
      should "pass through to app" do
        @app.expects(:call).with(call_args.merge(headers)).once
        @rack.call(call_args)
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
      
      context 'when a 301 rule matches' do
        setup do
          @rack = Rack::Rewrite.new(@app) do
            # ugh
            send(:'301', '/wiki/Yair_Flicker', '/yair')
          end
        end
        
        should_return_a_301_to { '/yair' }
      end
      
      context 'when a rewrite rule matches' do
        setup do
          @rack = Rack::Rewrite.new(@app) do
            rewrite '/wiki/Yair_Flicker', '/john'
          end
        end
        
        should_pass_through_to_app({'PATH_INFO' => '/john'})
      end
    end
  end
end