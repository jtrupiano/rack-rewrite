require 'rack/mime'

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
        
        # Creates a rewrite rule that will simply rewrite the REQUEST_URI,
        # PATH_INFO, and QUERY_STRING headers of the Rack environment.  The 
        # user's browser will continue to show the initially requested URL.
        # 
        #  rewrite '/wiki/John_Trupiano', '/john'
        #  rewrite %r{/wiki/(\w+)_\w+}, '/$1'
        #  rewrite %r{(.*)}, '/maintenance.html', :if => lambda { File.exists?('maintenance.html') }
        def rewrite(from, to, *args)
          options = args.last.is_a?(Hash) ? args.last : {}
          @rules << Rule.new(:rewrite, from, to, options[:if])
        end
        
        # Creates a redirect rule that will send a 301 when matching.
        #
        #  r301 '/wiki/John_Trupiano', '/john'
        #  r301 '/contact-us.php', '/contact-us'
        def r301(from, to, *args)
          options = args.last.is_a?(Hash) ? args.last : {}
          @rules << Rule.new(:r301, from, to, options[:if])
        end
        
        # Creates a redirect rule that will send a 302 when matching.
        #
        #  r302 '/wiki/John_Trupiano', '/john'
        #  r302 '/wiki/(.*)', 'http://www.google.com/?q=$1'
        def r302(from, to, *args)
          options = args.last.is_a?(Hash) ? args.last : {}
          @rules << Rule.new(:r302, from, to, options[:if])
        end
        
        # Creates a rule that will render a file if matched.
        #
        #  send_file /*/, 'public/system/maintenance.html', 
        #    :if => Proc.new { File.exists?('public/system/maintenance.html') }
        def send_file(from, to, *args)
          options = args.last.is_a?(Hash) ? args.last : {}
          @rules << Rule.new(:send_file, from, to, options[:if])          
        end
        
        # Creates a rule that will render a file using x-send-file
        # if matched.
        #
        #  x_send_file /*/, 'public/system/maintenance.html', 
        #    :if => Proc.new { File.exists?('public/system/maintenance.html') }
        def x_send_file(from, to, *args)
          options = args.last.is_a?(Hash) ? args.last : {}
          @rules << Rule.new(:x_send_file, from, to, options[:if])
        end        
    end

    # TODO: Break rules into subclasses
    class Rule #:nodoc:
      attr_reader :rule_type, :from, :to, :guard
      def initialize(rule_type, from, to, guard=nil) #:nodoc:
        @rule_type, @from, @to, @guard = rule_type, from, to, guard
      end

      def matches?(rack_env) #:nodoc:
        return false if !guard.nil? && !guard.call(rack_env)
        path = build_path_from_env(rack_env)
        if self.is_a_regexp?(self.from)
          path =~ self.from
        elsif self.from.is_a?(String)
          path == self.from
        else
          false
        end
      end

      # Either (a) return a Rack response (short-circuiting the Rack stack), or
      # (b) alter env as necessary and return true
      def apply!(env) #:nodoc:
        interpreted_to = self.interpret_to(env)
        case self.rule_type
        when :r301
          [301, {'Location' => interpreted_to, 'Content-Type' => Rack::Mime.mime_type(::File.extname(interpreted_to))}, [redirect_message(interpreted_to)]]
        when :r302
          [302, {'Location' => interpreted_to, 'Content-Type' => Rack::Mime.mime_type(::File.extname(interpreted_to))}, [redirect_message(interpreted_to)]]
        when :rewrite
          # return [200, {}, {:content => env.inspect}]
          env['REQUEST_URI'] = interpreted_to
          if q_index = interpreted_to.index('?')
            env['PATH_INFO'] = interpreted_to[0..q_index-1]
            env['QUERY_STRING'] = interpreted_to[q_index+1..interpreted_to.size-1]
          else
            env['PATH_INFO'] = interpreted_to
            env['QUERY_STRING'] = ''
          end
          true
        when :send_file
          [200, {
            'Content-Length' => ::File.size(interpreted_to).to_s,
            'Content-Type'   => Rack::Mime.mime_type(::File.extname(interpreted_to))
            }, [::File.read(interpreted_to)]]
        when :x_send_file
          [200, {
            'X-Sendfile'     => interpreted_to,
            'Content-Length' => ::File.size(interpreted_to).to_s,
            'Content-Type'   => Rack::Mime.mime_type(::File.extname(interpreted_to))
            }, []]
        else
          raise Exception.new("Unsupported rule: #{self.rule_type}")
        end
      end
      
      protected
        def interpret_to(env) #:nodoc:
          path = build_path_from_env(env)
          return interpret_to_proc(path, env) if self.to.is_a?(Proc)
          return computed_to(path) if compute_to?(path)
          self.to
        end
        
        def is_a_regexp?(obj)
          obj.is_a?(Regexp) || (Object.const_defined?(:Oniguruma) && obj.is_a?(Oniguruma::ORegexp))
        end

      private
        def interpret_to_proc(path, env)
          return self.to.call(match(path), env) if self.from.is_a?(Regexp)
          self.to.call(self.from, env)
        end

        def compute_to?(path)
          self.is_a_regexp?(from) && match(path)
        end

        def match(path) 
          self.from.match(path)
        end

        def computed_to(path)
          # is there a better way to do this?
          computed_to = self.to.dup
          computed_to.gsub!("$&",match(path).to_s)
          (match(path).size - 1).downto(1) do |num|
            computed_to.gsub!("$#{num}", match(path)[num].to_s)
          end
          return computed_to
        end
        
        # Construct the URL (without domain) from PATH_INFO and QUERY_STRING
        def build_path_from_env(env)
          path = env['PATH_INFO']
          path += "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].nil? || env['QUERY_STRING'].empty?
          path
        end
        
        def redirect_message(location)
          %Q(Redirecting to <a href="#{location}">#{location}</a>)
        end
    end
  end
end
