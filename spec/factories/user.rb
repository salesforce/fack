FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'Lettestthis1!' } # Ensure it meets your app's password validation
    admin { false } # Explicitly define if `admin` is a boolean column

    factory :admin_user do
      email { Faker::Internet.email(domain: 'admin.com') }
      admin { true }
    end
  end
end
