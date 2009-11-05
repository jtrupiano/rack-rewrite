require File.join(File.dirname(__FILE__), 'test_helper')

class RuleTest < Test::Unit::TestCase
  
  def self.should_pass_maintenance_tests
    context 'and the maintenance file does in fact exist' do
      setup { File.stubs(:exists?).returns(true) }

      should('match for the root')              { assert @rule.matches?('/') }
      should('match for a regular rails route') { assert @rule.matches?('/users/1') }
      should('match for an html page')          { assert @rule.matches?('/index.html') }
      should('not match for a css file')        { assert !@rule.matches?('/stylesheets/style.css') }
      should('not match for a jpg file')        { assert !@rule.matches?('/images/sls.jpg') }
      should('not match for a png file')        { assert !@rule.matches?('/images/sls.png') }
    end
  end
  
  def self.negative_lookahead_supported?
    RUBY_VERSION =~ /^1\.9/ || Object.const_defined?(:Oniguruma)
  end
  
  def negative_lookahead_regexp
    if RUBY_VERSION =~ /^1\.9/
      # have to use the constructor instead of the literal syntax b/c load errors occur in Ruby 1.8
      Regexp.new("(.*)$(?<!css|png|jpg)")
    else
      Oniguruma::ORegexp.new("(.*)$(?<!css|png|jpg)")
    end
  end
  
  context '#Rule#apply' do
    should 'set Location header to result of #interpret_to for a 301' do
      rule = Rack::Rewrite::Rule.new(:r301, %r{/abc}, '/def')
      env = {'PATH_INFO' => '/abc'}
      assert_equal rule.send(:interpret_to, '/abc'), rule.apply!(env)[1]['Location']
    end
    
    should 'keep the QUERYSTRING when a 301 rule matches a URL with a querystring' do
      rule = Rack::Rewrite::Rule.new(:r301, %r{/john(.*)}, '/yair$1')
      env = {'REQUEST_URI' => '/john?show_bio=1', 'PATH_INFO' => '/john', 'QUERYSTRING' => 'show_bio=1'}
      assert_equal '/yair?show_bio=1', rule.apply!(env)[1]['Location']
    end
    
    should 'keep the QUERYSTRING when a rewrite rule that requires a querystring matches a URL with a querystring' do
      rule = Rack::Rewrite::Rule.new(:rewrite, %r{/john(\?.*)}, '/yair$1')
      env = {'REQUEST_URI' => '/john?show_bio=1', 'PATH_INFO' => '/john', 'QUERYSTRING' => 'show_bio=1'}
      rule.apply!(env)
      assert_equal '/yair', env['PATH_INFO']
      assert_equal 'show_bio=1', env['QUERYSTRING']
      assert_equal '/yair?show_bio=1', env['REQUEST_URI']
    end
    
    should 'update the QUERYSTRING when a rewrite rule changes its value' do
      rule = Rack::Rewrite::Rule.new(:rewrite, %r{/(\w+)\?show_bio=(\d)}, '/$1?bio=$2')
      env = {'REQUEST_URI' => '/john?show_bio=1', 'PATH_INFO' => '/john', 'QUERYSTRING' => 'show_bio=1'}
      rule.apply!(env)
      assert_equal '/john', env['PATH_INFO']
      assert_equal 'bio=1', env['QUERYSTRING']
      assert_equal '/john?bio=1', env['REQUEST_URI']
    end

    should 'set Content-Type header to text/html for a 301 and 302' do
      [:r301, :r302].each do |rule_type|
        rule = Rack::Rewrite::Rule.new(rule_type, %r{/abc}, '/def')
        env = {'PATH_INFO' => '/abc'}
        assert_equal 'text/html', rule.apply!(env)[1]['Content-Type']
      end
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
    
    context 'Given a rule with a guard that checks for the presence of a file' do
      setup do
        @rule = Rack::Rewrite::Rule.new(:rewrite, %r{(.)*}, '/maintenance.html', lambda { 
          File.exists?('maintenance.html')
        })
      end
      
      context 'when the file exists' do
        setup do
          File.stubs(:exists?).returns(true)
        end
        
        should 'match' do
          assert @rule.matches?('/anything/should/match')
        end
      end
      
      context 'when the file does not exist' do
        setup do
          File.stubs(:exists?).returns(false)
        end
        
        should 'not match' do
          assert !@rule.matches?('/nothing/should/match')
        end
      end
    end
    
    context 'Given the capistrano maintenance.html rewrite rule given in our README' do
      setup do
        @rule = Rack::Rewrite::Rule.new(:rewrite, /.*/, '/system/maintenance.html', lambda { |from|
          maintenance_file = File.join('system', 'maintenance.html')
          File.exists?(maintenance_file) && !%w(css jpg png).any? {|ext| from =~ Regexp.new("\.#{ext}$")}
        })
      end
      should_pass_maintenance_tests
    end
    
    if negative_lookahead_supported?
      context 'Given the negative look-behind regular expression version of the capistrano maintenance.html rewrite rule given in our README' do
        setup do
          @rule = Rack::Rewrite::Rule.new(:rewrite, negative_lookahead_regexp, '/system/maintenance.html', lambda { |from|
            File.exists?(File.join('public', 'system', 'maintenance.html'))
          })
        end
        should_pass_maintenance_tests
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

    should 'call to with from when it is a lambda' do
      rule = Rack::Rewrite::Rule.new(:rewrite, 'a', lambda { |from, env| from * 2 })
      assert_equal 'aa', rule.send(:interpret_to, 'a')
    end

    should 'call to with from match data' do
      rule = Rack::Rewrite::Rule.new(:rewrite, %r{/person_(\d+)(.*)}, lambda {|match, env| "people-#{match[1].to_i * 3}#{match[2]}"})
      assert_equal 'people-3?show_bio=1', rule.send(:interpret_to, '/person_1?show_bio=1')
    end
  end
  
end
