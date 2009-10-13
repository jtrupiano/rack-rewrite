module Rack
  class Rewrite

    class RuleSet

      attr_reader :rules
      def initialize
        @rules = []
      end

      private
        # We're explicitly defining the functions for our DSL rather than
        # using method_missing
        %w(rewrite r301 r302).each do |meth|
          define_method(meth) do |from, to|
            @rules << Rule.new(meth.to_sym, from, to)
          end
        end
    end

    # TODO: Break rules into subclasses
    class Rule
      attr_reader :rule_type, :from, :to
      def initialize(rule_type, from, to)
        @rule_type, @from, @to = rule_type, from, to
      end

      def matches?(path)
        case self.from
        when Regexp
          path =~ self.from
        when String
          path == self.from
        else
          false
        end
      end

      def apply!(env, app)
        case rule_type
        when :r301
          [301, {'Location' => self.to}, ['Redirecting...']]
        when :r302
          [302, {'Location' => self.to}, ['Redirecting...']]
        when :rewrite
          # return [200, {}, {:content => env.inspect}]
          env['PATH_INFO'] = env['REQUEST_URI'] = self.to
          app.call(env)
        else
          raise Exception.new("Unsupported rule: #{rule.rule_type}")
        end
      end

      def rewrite?
        self.rule_type == :rewrite
      end

      def r301?
        self.rule_type == :r301
      end

      def r302?
        self.rule_type == :r302
      end
    end
    
  end
end