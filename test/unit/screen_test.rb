require 'test_helper'

class ScreenTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "name cannot be blank" do
    s = screens(:one)
    screen = Screen.new(s.attributes)
    screen.owner = users(:katie)
    screen.authentication_token="auth:nametest" # Must be unique
    screen.name = ""
    assert !screen.valid?, "Screen name is blank"
    screen.name = "Blah"
    assert screen.valid?, "Screen name has entry"
  end

  test "template cannot be blank or unassociated" do
    s = screens(:one)
    screen = Screen.new(s.attributes)
    screen.name = "New screen"
    screen.owner = users(:katie)
    screen.authentication_token="auth:tpltest" # Must be unique
    screen.template_id = ""
    assert !screen.valid?, "Screen template is blank"
    screen.template_id = 0
    assert !screen.valid?, "Screen template is unassociated"
    screen.template = templates(:one)
    assert screen.valid?, "Screen template is associated with one"
  end  

  test "owner must be group or user" do
    s = screens(:one)
    s.owner = users(:katie)
    assert s.valid?, "Screen owned by user"
    s.owner_type = "Pants"
    assert !s.valid?, "Screen cannot be owner by pants"
    s.owner_type = "User"
    assert s.valid?, "Screen can be owner by user"
    s.owner = groups(:wtg)
    assert s.valid?, "Screen can be owner by group"
    s.owner = nil
    s.owner_type = "Group"
    s.owner_id = ""
    assert !s.valid?, "Screen owner must be set"
    s.owner = nil
    s.owner_type = ""
    s.owner_id = users(:kristen).id
    assert !s.valid?, "Screen owner type must be set"
    s.owner = nil
    s.owner_type = "User"
    s.owner_id = 0
    assert !s.valid?, "Screen owner must be valid"
  end

  test "that a screen has an aspect ratio" do
    s = screens(:one)
    assert_equal 16, s.aspect_ratio[:width]
    assert_equal 9, s.aspect_ratio[:height]
  end

  test "a missing dimension produces an empty aspect ratio" do
    s = screens(:one)
    s.width = nil
    assert_equal "", s.aspect_ratio[:width]
    assert_equal "", s.aspect_ratio[:height]

    s = screens(:one)
    s.height = nil
    assert_equal "", s.aspect_ratio[:width]
    assert_equal "", s.aspect_ratio[:height]
  end

  test "a screen has positions" do
    s = screens(:one)
    assert !s.positions.empty?
  end

  test "a screen has fields" do
    s = screens(:one)
    assert !s.fields.empty?
  end

  test "screen offline online toggle" do
    s1 = screens(:one)
    assert s1.is_offline?
    assert_difference('Screen.offline.count', -1) do
      s1.mark_updated
    end
    assert s1.is_online?

    s2 = screens(:two)
    assert s2.is_offline?
    assert_difference('Screen.online.count') do
      s2.mark_updated
    end
    assert s2.is_online?
  end

  test "find by mac" do
    assert_equal screens(:two), Screen.find_by_mac('a1:b2:c3')
    assert_equal screens(:two), Screen.find_by_mac('a1b2c3')
    assert_equal screens(:two), Screen.find_by_mac('00:00:00:a1:b2:c3')
    assert_equal nil, Screen.find_by_mac('123')
  end

  test "mac get and set" do
    s = Screen.new()
    assert_equal nil, s.mac_address
    s.mac_address = 'abc123'
    assert_equal '00:00:00:ab:c1:23', s.mac_address
    assert_equal 'mac:abc123', s.authentication_token

    s.mac_address = ""
    assert s.authentication_token.nil?
  end

  test "clearing screen token" do
    # has a token
    s = screens(:one)
    assert_equal "auth:0123456789abcdef", s.authentication_token
    
    # clears token from memory but not table
    s.clear_screen_token
    assert_equal "", s.authentication_token
    s = Screen.where(:name => screens(:one).name).first
    assert_equal "auth:0123456789abcdef", s.authentication_token

    # clears token from table
    s.clear_screen_token!
    s = Screen.where(:name => screens(:one).name).first
    assert_equal "", s.authentication_token
  end

  test "auth_by detection" do
    s = Screen.new()
    s.mac_address = 'abc123'
    assert s.auth_by_mac?
    assert !s.unsecured?

    s = screens(:one)
    assert s.auth_by_token?
    assert !s.unsecured?

    s.authentication_token = "bogus:007"
    assert s.unsecured?
  end

  test "auth_action get and set" do
    s = Screen.new
    # bogus token
    s.auth_action = "bogus"
    s.update_authentication
    assert_equal Screen::AUTH_NO_SECURITY, s.auth_action

    # AUTH_NO_SECURITY resets tokens
    s.authentication_token = "auth:123"
    s.new_temp_token = "new:123"
    s.auth_action = Screen::AUTH_NO_SECURITY
    s.update_authentication
    assert s.authentication_token.blank?
    assert s.new_temp_token.blank?

    # getting new token
    s.auth_action = Screen::AUTH_NEW_TOKEN
    s.new_temp_token = Screen::generate_temp_token
    s.update_authentication
    assert_equal Screen::AUTH_NEW_TOKEN, s.auth_action

    # already have token
    s = screens(:one)
    assert_equal Screen::AUTH_KEEP_TOKEN, s.auth_action

    # legacy token
    s.mac_address = 'abc123'
    assert_equal Screen::AUTH_LEGACY_SCREEN, s.auth_action
  end
end
