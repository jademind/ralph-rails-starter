require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects to login when not authenticated" do
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "displays dashboard when authenticated" do
    sign_in_as(User.take)
    get dashboard_path
    assert_response :success
  end
end
