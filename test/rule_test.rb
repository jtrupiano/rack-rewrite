require 'test_helper'

class RuleTest < Test::Unit::TestCase

  context '#Rule#apply' do
    should 'set Location header to result of #interpret_to for a 301' do
      rule = Rack::Rewrite::Rule.new(:r301, %r{/abc}, '/def')
      env = {'PATH_INFO' => '/abc'}
      assert_equal rule.send(:interpret_to, '/abc'), rule.apply!(env)[1]['Location']
    end
  end
  
  context 'Rule#matches' do
    
    context 'Given any rule with a "from" string of /features' do
      setup do
        @rule = Rack::Rewrite::Rule.new(:rewrite, '/features', '/facial_features')
      end
      
      should 'match PATH_INFO of /features' do
        assert @rule.matches?("/features")
      end
      
      should 'not match PATH_INFO of /features.xml' do
        assert !@rule.matches?("/features.xml")
      end
      
      should 'not match PATH_INFO of /my_features' do
        assert !@rule.matches?("/my_features")
      end
    end
    
    context 'Given any rule with a "from" regular expression of /features(.*)' do
      setup do
        @rule = Rack::Rewrite::Rule.new(:rewrite, %r{/features(.*)}, '/facial_features$1')
      end
    
      should 'match PATH_INFO of /features' do
        assert @rule.matches?("/features")
      end
    
      should 'match PATH_INFO of /features.xml' do
        assert @rule.matches?('/features.xml')
      end
    
      should 'match PATH_INFO of /features/1' do
        assert @rule.matches?('/features/1')
      end
    
      should 'match PATH_INFO of /features?filter_by=name' do
        assert @rule.matches?('/features?filter_by_name=name')
      end
    
      should 'match PATH_INFO of /features/1?hide_bio=1' do
        assert @rule.matches?('/features/1?hide_bio=1')
      end
    end
  end
  
  context 'Rule#interpret_to' do
    
    should 'return #to when #from is a string' do
      rule = Rack::Rewrite::Rule.new(:rewrite, '/abc', '/def')
      assert_equal '/def', rule.send(:interpret_to, '/abc')
    end
    
    should 'replace $1 on a match' do
      rule = Rack::Rewrite::Rule.new(:rewrite, %r{/person_(\d+)}, '/people/$1')
      assert_equal '/people/1', rule.send(:interpret_to, "/person_1")
    end
    
    should 'be able to catch querystrings with a regexp match' do
      rule = Rack::Rewrite::Rule.new(:rewrite, %r{/person_(\d+)(.*)}, '/people/$1$2')
      assert_equal '/people/1?show_bio=1', rule.send(:interpret_to, '/person_1?show_bio=1')
    end
    
    should 'be able to make 10 replacements' do
      # regexp to reverse 10 characters
      rule = Rack::Rewrite::Rule.new(:rewrite, %r{(\w)(\w)(\w)(\w)(\w)(\w)(\w)(\w)(\w)(\w)}, '$10$9$8$7$6$5$4$3$2$1')
      assert_equal 'jihgfedcba', rule.send(:interpret_to, "abcdefghij")
    end
  end
  
end
