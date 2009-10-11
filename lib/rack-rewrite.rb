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
    
    # This will probably have to change as rule matching gets more complicated
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
