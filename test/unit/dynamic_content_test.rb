require 'test_helper'
include ActionDispatch::TestProcess

class DynamicContentTest < ActiveSupport::TestCase
  test "New config is created" do
    dynamic = DynamicContent.new
    assert_equal({}.class, dynamic.config.class)
    dynamic.config['var'] = 'foo'
    assert_equal 'foo', dynamic.config['var']
  end

  test "Save and load config" do
    dynamic = DynamicContent.new
    dynamic.config['var'] = 'foo'
    dynamic.config['other'] = 123
    dynamic.save_config

    dynamic.config = nil
    dynamic.load_config

    assert_equal 'foo', dynamic.config['var']
    assert_equal 123, dynamic.config['other']
  end

  test "Auto save and load" do
    dynamic = DynamicContent.new
    dynamic.name = 'Dynamic Content'
    dynamic.user = users(:katie)
    dynamic.config['var'] = 'foo'
    dynamic.config['other'] = 123
    dynamic.save

    fresh = DynamicContent.find(dynamic.id)
    assert_equal 'foo', fresh.config['var']
    assert_equal 123, fresh.config['other']
  end
  
  test "Expire children is called" do
    dynamic = DynamicContent.where("name = 'Sample Dynamic Content Feed'").first
    child = Ticker.where("name = 'Concerto TV Google Play'").first
    
    assert !child.is_expired?
    dynamic.expire_children
    
    child.reload
    assert child.is_expired?
  end
end
