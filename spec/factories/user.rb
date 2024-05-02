# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    # Define attributes for user
    email { 'vijay@gmail.com' }
    password { 'Lettestthis1!' }

    factory :admin_user do
      # Define attributes for user
      email { 'vijayadmin@gmail.com' }
      admin { true }
    end
  end
end
