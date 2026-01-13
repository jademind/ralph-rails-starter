require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @record = User.new
  end

  test "default permissions deny all actions" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_not policy.index?, "Default policy should deny index"
    assert_not policy.show?, "Default policy should deny show"
    assert_not policy.create?, "Default policy should deny create"
    assert_not policy.update?, "Default policy should deny update"
    assert_not policy.destroy?, "Default policy should deny destroy"
  end

  test "new? delegates to create?" do
    policy = ApplicationPolicy.new(@user, @record)
    assert_equal policy.create?, policy.new?
  end

  test "edit? delegates to update?" do
    policy = ApplicationPolicy.new(@user, @record)
    assert_equal policy.update?, policy.edit?
  end

  test "Scope#resolve raises NotImplementedError by default" do
    scope = ApplicationPolicy::Scope.new(@user, User.all)

    error = assert_raises(NoMethodError) do
      scope.resolve
    end

    assert_match(/You must define #resolve/, error.message)
  end

  test "policy initializes with user and record" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_equal @user, policy.user
    assert_equal @record, policy.record
  end

  test "scope initializes with user and scope" do
    scope_relation = User.all
    scope = ApplicationPolicy::Scope.new(@user, scope_relation)

    assert_equal @user, scope.user
    assert_equal scope_relation, scope.scope
  end
end
