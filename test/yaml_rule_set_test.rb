require 'test_helper'
require 'lib/rack/rewrite/yaml_rule_set'


class YamlRuleSetTest < Test::Unit::TestCase

    TEST_ROOT = File.dirname(__FILE__)


  context "When used through a rack app" do

    setup do
      @file_name = File.join(TEST_ROOT, 'rules.yml')
      @app = Class.new { def call(app); true; end }.new
    end

    should 'be initialized when the app is created' do
      Rack::Rewrite::YamlRuleSet.expects(:new).with(all_of({:file_name => @file_name}))
      @rack = Rack::Rewrite.new(@app, 
        :klass => Rack::Rewrite::YamlRuleSet, 
        :options => {:file_name => @file_name}
      )
    end

  end

  context "When given some rules" do

    setup do
      @file_name = File.join(TEST_ROOT, 'rules.yml')
      @rule_set =  Rack::Rewrite::YamlRuleSet.new(:file_name => @file_name)
    end

    should "correctly load up 3 rules" do
      assert_equal 3, @rule_set.rules.length
    end

    should "correctly perform a regexed rule" do
      env = rack_env_for("/something/abc")
      rule = @rule_set.rules.detect{|a| a.matches?(env)}
      assert_not_nil rule
      assert_equal '/something/regexed_path', rule.apply!(env)[1]['Location']
    end

    should "correctly apply host option" do
      env = rack_env_for("/withhost")
      rule = @rule_set.rules.detect{|a| a.matches?(env)}
      assert_nil rule

      env = rack_env_for("/withhost", 'SERVER_NAME' => 'example.com', "SERVER_PORT" => "8080")
      rule = @rule_set.rules.detect{|a| a.matches?(env)}
      assert_not_nil rule
      assert_equal '/anotherhost', rule.apply!(env)[1]['Location']
    end

  end
end