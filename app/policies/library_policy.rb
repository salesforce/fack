class LibraryPolicy < ApplicationPolicy
    attr_reader :user, :library
  
    def initialize(user, library)
      @user = user
      @library = library
    end

    def create?
      user.admin?
    end
  
    def update?
      user.admin? || library.user_id == user.id
    end
  end