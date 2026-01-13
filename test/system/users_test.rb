require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    Capybara.reset_sessions!
    @user = users(:one)
    @other_user = users(:two)
  end

  test "visiting the user index page" do
    sign_in_as(@user)

    visit users_path

    assert_selector "h1", text: I18n.t("users.index.title")
    assert_text @user.email_address
    assert_text @other_user.email_address
  end
end
