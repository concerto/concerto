class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def cas
    cas_hash = request.env["omniauth.auth"]
    user = User.from_omniauth(cas_hash)

    # Check if users table is empty
    if !User.exists?
      # First user is an admin
      first_user_setup = true
      user.is_admin = true

      # Error reporting
      user.receive_moderation_notifications = true
      user.confirmed_at = Date.today

      if ConcertoConfig["setup_complete"] == false
        ConcertoConfig.set("setup_complete", "true")
        ConcertoConfig.set("send_errors", "true")
      end

      user.save

      # Create Concerto Admin Group
      group = Group.where(:name => "Concerto Admins").first_or_create
      membership = Membership.create(:user_id => user.id, :group_id => group.id, :level => Membership::LEVELS[:leader])
      process_notification(membership, {:user => user, :group => group, :adder => user}, :action => 'create', :owner => user)
    
      # Set devise session param and sign in user
      session["devise.user_attributes"] = user.attributes
      flash.notice = "Signed in through RPI CAS"
      sign_in_and_redirect user
    end


    if !user 
      flash.notice = "Failed to Sign in with RPI CAS"
      redirect_to "/"
    elsif user.persisted?
      flash.notice = "Signed in through RPI CAS"
      session["devise.user_attributes"] = user.attributes
      sign_in_and_redirect user
    else
      flash.notice = "Signed in through RPI CAS"
      session["devise.user_attributes"] = user.attributes
      sign_in_and_redirect user
    end
  end

end