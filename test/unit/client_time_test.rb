require 'test_helper'

class ClientTimeTest < ActiveSupport::TestCase
  test "validations" do 
    c = ClientTime.new(:name => 'test', :user => users(:admin))
    c.duration = 0
    assert !c.valid?

    c.duration = 60
    assert !c.valid?

    c.duration = 59
    assert c.valid?
  end
end
