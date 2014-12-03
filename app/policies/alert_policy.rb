class AlertPolicy < ApplicationPolicy
  def index?
    admin_or_related
  end

  def create?
    admin_or_related
  end

  def show?
    admin_or_related
  end

  def new?
    admin_or_related
  end

  def update?
    admin_or_related
  end

  def destroy?
    admin_or_related
  end

  class Scope < Scope
    def resolve
      scope
    end
  end

  private

  def admin_or_related
    true # user.admin?
  end
end
