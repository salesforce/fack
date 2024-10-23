# frozen_string_literal: true

module Delayed
  module Backend
    module ActiveRecord
      class JobPolicy
        attr_reader :user, :job

        def initialize(user, job)
          @user = user
          @job = job
        end

        def update?
          user.admin?
        end

        def destroy?
          user.admin?
        end
      end
    end
  end
end
