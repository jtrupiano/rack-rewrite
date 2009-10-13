$: << File.expand_path(File.dirname(__FILE__))

require 'rack-rewrite/rule'

module Rack
  class Rewrite
    def initialize(app, &rule_block)
      @app = app
      @rule_set = RuleSet.new
      @rule_set.instance_eval(&rule_block) if block_given?
    end
    
    def call(env)
      if matched_rule = find_first_matching_rule(env)
        rack_response = matched_rule.apply!(env)
        # Don't invoke the app if applying the rule returns a rack response
        return rack_response unless rack_response === true
      end
      @app.call(env)
    end
        
    private
    
      def find_first_matching_rule(env) #:nodoc
        @rule_set.rules.detect { |rule| rule.matches?(env['PATH_INFO']) }
      end
    
  end
end
