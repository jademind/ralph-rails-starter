require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  # Index tests
  test "should get index when authenticated" do
    sign_in_as(@user)
    get users_path
    assert_response :success
  end

  test "should redirect to sign in when not authenticated" do
    get users_path
    assert_redirected_to new_session_path
  end

  # Show tests
  test "should show user when authenticated" do
    sign_in_as(@user)
    get user_path(@user)
    assert_response :success
  end

  test "should show other user when authenticated" do
    sign_in_as(@user)
    get user_path(@other_user)
    assert_response :success
  end

  test "should redirect to sign in when not authenticated on show" do
    get user_path(@user)
    assert_redirected_to new_session_path
  end

  # Edit tests
  test "should get edit for own profile" do
    sign_in_as(@user)
    get edit_user_path(@user)
    assert_response :success
  end

  test "should not authorize edit for other user profile" do
    sign_in_as(@user)
    get edit_user_path(@other_user)
    assert_redirected_to root_path
    assert_equal I18n.t("users.authorization.unauthorized"), flash[:alert]
  end

  test "should redirect to sign in when not authenticated on edit" do
    get edit_user_path(@user)
    assert_redirected_to new_session_path
  end

  # Update tests
  test "should update own profile" do
    sign_in_as(@user)
    patch user_path(@user), params: { user: { email_address: "newemail@example.com" } }
    assert_redirected_to user_path(@user)

    @user.reload
    assert_equal "newemail@example.com", @user.email_address
  end

  test "should not authorize update for other user profile" do
    sign_in_as(@user)
    original_email = @other_user.email_address

    patch user_path(@other_user), params: { user: { email_address: "hacked@example.com" } }
    assert_redirected_to root_path
    assert_equal I18n.t("users.authorization.unauthorized"), flash[:alert]

    @other_user.reload
    assert_equal original_email, @other_user.email_address
  end

  test "should redirect to sign in when not authenticated on update" do
    patch user_path(@user), params: { user: { email_address: "test@example.com" } }
    assert_redirected_to new_session_path
  end

  # Destroy tests
  test "should destroy own account" do
    sign_in_as(@user)
    assert_difference("User.count", -1) do
      delete user_path(@user)
    end
    assert_redirected_to users_path
  end

  test "should not authorize destroy for other user account" do
    sign_in_as(@user)
    assert_no_difference("User.count") do
      delete user_path(@other_user)
    end
    assert_redirected_to root_path
    assert_equal I18n.t("users.authorization.unauthorized"), flash[:alert]
  end

  test "should redirect to sign in when not authenticated on destroy" do
    delete user_path(@user)
    assert_redirected_to new_session_path
  end
end
