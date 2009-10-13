require 'test_helper'

class RuleTest < Test::Unit::TestCase

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
end
