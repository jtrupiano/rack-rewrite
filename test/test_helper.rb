require 'rubygems'
require 'test/unit'
gem 'shoulda', '~> 2.10.2'
require 'shoulda'
gem 'mocha', '~> 0.9.7'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rack-rewrite'

class Test::Unit::TestCase
end

TEST_ROOT = File.dirname(__FILE__)

## mock logging so we can test it
module Rack
  class Rewrite
    class Rule
      attr_accessor :logs      
      alias :old_initialize :initialize
      def initialize(*args) #:nodoc:
        @logs = []
        old_initialize(*args)
      end
      private
      def log(env, message)
        @logs << message
      end
    end
  end
end