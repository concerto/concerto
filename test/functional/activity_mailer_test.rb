require 'test_helper'

class ActivityMailerTest < ActionMailer::TestCase
  test "content_moderated" do
    mail = ActivityMailer.content_moderated
    assert_equal "Content moderated", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
