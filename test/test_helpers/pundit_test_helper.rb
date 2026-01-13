# Helper module for testing Pundit policies
# Include this in your tests to get convenient policy testing methods
module PunditTestHelper
  # Assert that a policy permits an action
  # Example: assert_permit(user, post, :update)
  def assert_permit(user, record, action)
    policy = policy_class(record).new(user, record)
    assert policy.public_send("#{action}?"),
           "Expected #{policy.class} to permit #{action} on #{record}, but it didn't"
  end

  # Assert that a policy forbids an action
  # Example: assert_not_permit(user, post, :destroy)
  def assert_not_permit(user, record, action)
    policy = policy_class(record).new(user, record)
    assert_not policy.public_send("#{action}?"),
               "Expected #{policy.class} to forbid #{action} on #{record}, but it permitted it"
  end

  # Assert that an action raises a Pundit::NotAuthorizedError
  # Example: assert_pundit_unauthorized { delete user_path(other_user) }
  def assert_pundit_unauthorized(&block)
    assert_raises(Pundit::NotAuthorizedError, &block)
  end

  private
    # Get the policy class for a given record
    def policy_class(record)
      if record.is_a?(Class)
        "#{record}Policy".constantize
      else
        "#{record.class}Policy".constantize
      end
    end
end

# Include helper in all test cases
ActiveSupport::TestCase.include(PunditTestHelper)
