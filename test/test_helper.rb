require 'rubygems'
require 'test/unit'
gem 'shoulda', '~> 2.10.2'
require 'shoulda'
gem 'mocha', '~> 0.9.7'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rack/rewrite'

class Test::Unit::TestCase
end
