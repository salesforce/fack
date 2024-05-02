# frozen_string_literal: true

require 'application_system_test_case'

class ApiTokensTest < ApplicationSystemTestCase
  setup do
    @api_token = api_tokens(:one)
  end

  test 'visiting the index' do
    visit api_tokens_url
    assert_selector 'h1', text: 'Api tokens'
  end

  test 'should create api token' do
    visit api_tokens_url
    click_on 'New api token'

    click_on 'Create Api token'

    assert_text 'Api token was successfully created'
    click_on 'Back'
  end

  test 'should update Api token' do
    visit api_token_url(@api_token)
    click_on 'Edit this api token', match: :first

    click_on 'Update Api token'

    assert_text 'Api token was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Api token' do
    visit api_token_url(@api_token)
    click_on 'Destroy this api token', match: :first

    assert_text 'Api token was successfully destroyed'
  end
end
