require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |driver_option|
    driver_option.add_argument("--disable-search-engine-choice-screen")
    driver_option.add_argument("--disable-gpu")
    driver_option.add_argument("--no-sandbox")
    driver_option.add_argument("--disable-dev-shm-usage")
    driver_option.add_argument("--disable-software-rasterizer")
    # Disable blink features that can cause flakiness
    driver_option.add_argument("--disable-blink-features=AutomationControlled")
  end

  # Helper method for signing in during system tests
  def sign_in_as(user)
    visit new_session_path

    # Fill in using input names to avoid placeholder matching flakiness.
    find("input[name='email_address']").set(user.email_address)
    find("input[name='password']").set("password")

    click_on I18n.t("sessions.new.sign_in")

    # Warten bis Redirect durch ist
    assert_no_current_path new_session_path, wait: 5
    assert_current_path dashboard_path, wait: 5
    assert_selector "h1", text: I18n.t("dashboard.index.title"), wait: 5
  end
end
