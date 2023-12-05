require 'rails_helper'

RSpec.feature 'User login', type: :feature do
  let!(:user) { create(:user, email: 'user@example.com', password: 'Password1!') }

  scenario 'User logs in successfully' do
    visit new_session_path # Replace with your login path

    fill_in 'Email', with: 'user@example.com'
    fill_in 'Password', with: 'Password1!'
    click_button 'Login'

    expect(page).to have_text('Logout') # Or any other indication of a successful login
  end

  scenario 'User fails to login with wrong credentials' do
    visit new_session_path

    fill_in 'Email', with: 'wrong@example.com'
    fill_in 'Password', with: 'wrongpassword'
    click_button 'Login'

    expect(page).to have_text('Error logging in') # Or the error message you display
  end
end
