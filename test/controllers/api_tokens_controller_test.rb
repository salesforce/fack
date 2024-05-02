# frozen_string_literal: true

require 'test_helper'

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_token = api_tokens(:one)
  end

  test 'should get index' do
    get api_tokens_url
    assert_response :success
  end

  test 'should get new' do
    get new_api_token_url
    assert_response :success
  end

  test 'should create api_token' do
    assert_difference('ApiToken.count') do
      post api_tokens_url, params: { api_token: {} }
    end

    assert_redirected_to api_token_url(ApiToken.last)
  end

  test 'should show api_token' do
    get api_token_url(@api_token)
    assert_response :success
  end

  test 'should get edit' do
    get edit_api_token_url(@api_token)
    assert_response :success
  end

  test 'should update api_token' do
    patch api_token_url(@api_token), params: { api_token: {} }
    assert_redirected_to api_token_url(@api_token)
  end

  test 'should destroy api_token' do
    assert_difference('ApiToken.count', -1) do
      delete api_token_url(@api_token)
    end

    assert_redirected_to api_tokens_url
  end
end
