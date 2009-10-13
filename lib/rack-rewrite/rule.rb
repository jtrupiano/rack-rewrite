module Rack
  class Rewrite
    class RuleSet
      attr_reader :rules
      def initialize #:nodoc:
        @rules = []
      end

      protected
        # We're explicitly defining private functions for our DSL rather than
        # using method_missing
        
        # Creates a rewrite rule that will simply rewrite the REQUEST_URI and
        # PATH_INFO headers of the Rack environment.  The user's browser
        # will continue to show the initially requested URL.
        # 
        #  rewrite '/wiki/John_Trupiano', '/john'
        #  rewrite %r{/wiki/(\w+)_\w+}, '/$1'        
        def rewrite(from, to)
          @rules << Rule.new(:rewrite, from, to)
        end
        
        # Creates a redirect rule that will send a 301 when matching.
        #
        #  r301 '/wiki/John_Trupiano', '/john'
        #  r301 '/contact-us.php', '/contact-us'
        def r301(from, to)
          @rules << Rule.new(:r301, from, to)
        end
        
        # Creates a redirect rule that will send a 302 when matching.
        #
        #  r302 '/wiki/John_Trupiano', '/john'
        #  r302 '/wiki/(.*)', 'http://www.google.com/?q=$1'
        def r302(from, to)
          @rules << Rule.new(:r302, from, to)
        end
    end

    # TODO: Break rules into subclasses
    class Rule #:nodoc:
      attr_reader :rule_type, :from, :to
      def initialize(rule_type, from, to) #:nodoc:
        @rule_type, @from, @to = rule_type, from, to
      end

      def matches?(path) #:nodoc:
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
      def apply!(env) #:nodoc:
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
          raise Exception.new("Unsupported rule: #{self.rule_type}")
        end
      end
      
      private
        # is there a better way to do this?
        def interpret_to(path) #:nodoc:
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