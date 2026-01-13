require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "displays home page when not authenticated" do
    get root_path
    assert_response :success
  end

  test "redirects to dashboard when authenticated" do
    sign_in_as(User.take)
    get root_path
    assert_redirected_to dashboard_path
  end
end
