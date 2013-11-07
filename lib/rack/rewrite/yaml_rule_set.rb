require 'rack/mime'
require 'yaml'

module Rack
  class Rewrite
    class YamlRuleSet

      attr_reader :rules

      #  Provides a method for setting the rewrite rules in a yaml file.
      #  
      #  Relys on Yaml to correctly produce ruby types like regex and then pushes
      #  those values into a ruleset - giving the same result as if the DSL was 
      #  used.

      def initialize(options)
        @options = options
        @rules = generate_rules(load_rules)
      end

      def load_rules
        YAML.load(::File.open(@options[:file_name]).read)
      end

      def generate_rules(yaml)
        yaml.map do |rule|
          options = rule["options"] || {}
          options.keys.each do |key|
            options[(key.to_sym rescue key) || key] = options.delete(key)
          end
          Rule.new(rule["method"].to_sym, rule["from"], rule["to"], options)
        end
      end

    end
  end
end