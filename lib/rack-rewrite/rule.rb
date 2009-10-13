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

      # Either (a) return a Rack response (short-circuting the Rack stack), or
      # (b) alter env as necessary and return true
      def apply!(env)
        interpreted_to = self.send(:interpret_to, env['PATH_INFO'])
        case self.rule_type
        when :r301
          [301, {'Location' => interpreted_to}, ['Redirecting...']]
        when :r302
          [302, {'Location' => interpreted_to}, ['Redirecting...']]
        when :rewrite
          # return [200, {}, {:content => env.inspect}]
          env['PATH_INFO'] = env['REQUEST_URI'] = interpreted_to
          true
        else
          raise Exception.new("Unsupported rule: #{rule.rule_type}")
        end
      end
      
      private
        # is there a better way to do this?
        def interpret_to(path)
          if self.from.is_a?(Regexp)
            if from_match_data = self.from.match(path)
              computed_to = self.to.dup
              (from_match_data.size - 1).downto(1) do |num|
                computed_to.gsub!("$#{num}", from_match_data[num])
              end
              return computed_to
            end
          end
          self.to
        end
    end
    
  end
end