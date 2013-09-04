require 'test_helper'

class ScreenAuthTest < ActionController::IntegrationTest
  #fixtures :all
  fixtures :users, :screens, :groups, :templates

  test "screen authorization flow" do
    #ConcertoConfig.set(:allow_user_screen_creation, true)
    screen_session = open_session
    #user_session = open_session


    # Initial visit by screen to get token
    screen_session.get "/frontend"
    screen_session.assert_response :success
    assert_equal screen_session.session[:screen_temp_token].length, 6
    token_from_screen = screen_session.session[:screen_temp_token]

    # Admin logs in and sets up the screen using the token
    screen = create_screen_as_admin(token_from_screen)

    # Now the screen refreshes, and based on its session data,
    # it is redirected to its frontend URL.
    screen_session.get "/frontend"
    screen_session.assert_redirected_to frontend_screen_path(screen)
    screen_session.follow_redirect!
    screen_session.assert_response :success
  end

  def create_screen_as_admin(temp_token)
    screen = nil
    user_session = open_session do |sess|
      sess.post "/users/sign_in", :user => {:email => users(:admin).email, :password => 'adminpassword'}
      sess.assert_redirected_to dashboard_path

      # Set up the screen as an administrator
      # (The administrator would manually copy the token from the screen)
      sess.post "/screens", {
        :screen => {
          :name => "Auth Test Screen",
          :is_public => false,
          :auth_action => Screen::AUTH_NEW_TOKEN,
          :new_temp_token => temp_token,
          :template_id => templates(:one).id
        },
        :owner => "User-"+users(:katie).id.to_s,
      }
      sess.assert_response :redirect
      assert sess.flash[:notice].include? "success"
      screen = sess.assigns(:screen)
      sess.assert_redirected_to screen_path(screen)
    end
    screen
  end
end
