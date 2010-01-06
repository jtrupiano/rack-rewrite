require 'test_helper'

class RackRewriteTest < Test::Unit::TestCase

  def call_args(overrides={})
    {'REQUEST_URI' => '/wiki/Yair_Flicker', 'PATH_INFO' => '/wiki/Yair_Flicker', 'QUERY_STRING' => ''}.merge(overrides)
  end
  
  def call_args_no_req(overrides={})
    {'PATH_INFO' => '/wiki/Yair_Flicker', 'QUERY_STRING' => ''}.merge(overrides)
  end
  
  def self.should_not_halt
    should "not halt the rack chain" do
      @app.expects(:call).once
      @rack.call(call_args)
    end
  end
  
  def self.should_be_a_rack_response
    should 'be a rack a response' do
      ret = @rack.call(call_args)
      assert ret.is_a?(Array), 'return value is not a valid rack response'
      assert_equal 3, ret.size, 'should have 3 arguments'
    end
  end
  
  def self.should_halt
    should "should halt the rack chain" do
      @app.expects(:call).never
      @rack.call(call_args)
    end
    should_be_a_rack_response
  end
      
  def self.should_location_redirect_to(location, code)
    should "respond with http status code #{code}" do
      ret = @rack.call(call_args)
      assert_equal code, ret[0]
    end
    should 'send a location header' do
      ret = @rack.call(call_args)
      assert_equal location, ret[1]['Location'], 'Location is incorrect'
    end
  end
  
  context 'Given an app' do
    setup do
      @app = Class.new { def call(app); true; end }.new
    end
  
    context 'when no rewrite rule matches' do
      setup {
        @rack = Rack::Rewrite.new(@app)
      }
      should_not_halt
    end
    
    context 'when a 301 rule matches' do
      setup {
        @rack = Rack::Rewrite.new(@app) do
          r301 '/wiki/Yair_Flicker', '/yair'
        end
      }
      should_halt
      should_location_redirect_to('/yair', 301)
    end
    
    context 'when a 302 rule matches' do
      setup {
        @rack = Rack::Rewrite.new(@app) do
          r302 '/wiki/Yair_Flicker', '/yair'
        end
      }
      should_halt
      should_location_redirect_to('/yair', 302)
    end
    
    context 'when a rewrite rule matches' do
      setup {
        @rack = Rack::Rewrite.new(@app) do
          rewrite '/wiki/Yair_Flicker', '/john'
        end
      }
      should_not_halt
      
      context 'the env' do
        setup do
          @initial_args = call_args.dup
          @rack.call(@initial_args)
        end
        
        should "set PATH_INFO to '/john'" do
          assert_equal '/john', @initial_args['PATH_INFO']
        end
        should "set REQUEST_URI to '/john'" do
          assert_equal '/john', @initial_args['REQUEST_URI']
        end
        should "set QUERY_STRING to ''" do
          assert_equal '', @initial_args['QUERY_STRING']
        end
      end
    end

    context 'when a rewrite rule matches but there is no REQUEST_URI set' do
      setup {
        @rack = Rack::Rewrite.new(@app) do
          rewrite '/wiki/Yair_Flicker', '/john'
        end
      }
      should_not_halt

      context 'the env' do
        setup do
          @initial_args = call_args_no_req.dup
          @rack.call(@initial_args)
        end

        should "set PATH_INFO to '/john'" do
          assert_equal '/john', @initial_args['PATH_INFO']
        end
        should "set REQUEST_URI to '/john'" do
          assert_equal '/john', @initial_args['REQUEST_URI']
        end
        should "set QUERY_STRING to ''" do
          assert_equal '', @initial_args['QUERY_STRING']
        end
      end
    end
    
  end
end
