# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Check if the admin user already exists to avoid creating duplicates
unless User.find_by(email: 'admin@fack.com')
  User.create!(
    email: 'admin@fack.com',
    password: ENV.fetch('TEST_PASSWORD', nil),
    admin: true,
    created_at: Time.now,
    updated_at: Time.now
  )
end

unless User.find_by(email: 'normal@fack.com')
  User.create!(
    email: 'normal@fack.com',
    password: ENV.fetch('TEST_PASSWORD', nil),
    admin: false,
    created_at: Time.now,
    updated_at: Time.now
  )
end
