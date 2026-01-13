class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Handle authorization failures
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private
    def user_not_authorized
      flash[:alert] = I18n.t("users.authorization.unauthorized")
      redirect_to(request.referrer || root_path)
    end

    # Override Pundit's current_user method to use Rails 8's authentication
    def pundit_user
      Current.session&.user
    end
end
