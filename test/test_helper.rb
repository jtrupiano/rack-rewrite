require 'rubygems'
require 'bundler/setup'

Bundler.require :default, :development

require 'test/unit'

class Test::Unit::TestCase
end

TEST_ROOT = File.dirname(__FILE__)


class MockLogger
  attr_reader :logs
  def initialize
    @logs = []
  end
  def write(message, &block)
    @logs << message
  end
  alias :info :write
end