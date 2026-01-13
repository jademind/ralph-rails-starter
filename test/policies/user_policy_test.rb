require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  test "index? allows all authenticated users" do
    policy = UserPolicy.new(@user, User)
    assert policy.index?, "Authenticated users should be able to view user list"
  end

  test "show? allows all authenticated users" do
    policy = UserPolicy.new(@user, @other_user)
    assert policy.show?, "Authenticated users should be able to view any user profile"
  end

  test "update? allows users to edit their own profile" do
    policy = UserPolicy.new(@user, @user)
    assert policy.update?, "Users should be able to edit their own profile"
  end

  test "update? denies users from editing other profiles" do
    policy = UserPolicy.new(@user, @other_user)
    assert_not policy.update?, "Users should not be able to edit other users' profiles"
  end

  test "destroy? allows users to delete their own account" do
    policy = UserPolicy.new(@user, @user)
    assert policy.destroy?, "Users should be able to delete their own account"
  end

  test "destroy? denies users from deleting other accounts" do
    policy = UserPolicy.new(@user, @other_user)
    assert_not policy.destroy?, "Users should not be able to delete other users' accounts"
  end

  test "edit? delegates to update?" do
    policy = UserPolicy.new(@user, @user)
    assert_equal policy.update?, policy.edit?
  end

  test "Scope#resolve returns all users" do
    scope = UserPolicy::Scope.new(@user, User.all)
    assert_equal User.count, scope.resolve.count, "All users should be visible to authenticated users"
  end
end
