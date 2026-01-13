# Policy for User authorization
# Defines what actions users can perform on User records
class UserPolicy < ApplicationPolicy
  # Users can view the list of users
  def index?
    true
  end

  # Users can view any user profile
  def show?
    true
  end

  # Only the user themselves can update their own profile
  def update?
    user == record
  end

  # Only the user themselves can delete their own account
  def destroy?
    user == record
  end

  # Scope for filtering user collections
  class Scope < ApplicationPolicy::Scope
    def resolve
      # All authenticated users can see all users
      # Modify this based on your requirements
      scope.all
    end
  end
end
