require 'rubygems'
require 'bundler/setup'

Bundler.require :default, :development

require 'test/unit'

class Test::Unit::TestCase
end

def supported_status_codes
  [:r301, :r302]
end