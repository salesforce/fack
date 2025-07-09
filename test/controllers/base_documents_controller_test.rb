# frozen_string_literal: true

require 'test_helper'

class BaseDocumentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test 'should get index with valid ISO 8601 since parameter' do
    get documents_path, params: { since: '2023-12-01T10:30:00Z' }
    assert_response :success
  end

  test 'should get index with valid RFC 3339 since parameter' do
    get documents_path, params: { since: '2023-12-01T10:30:00+00:00' }
    assert_response :success
  end

  test 'should get index with valid date only since parameter' do
    get documents_path, params: { since: '2023-12-01' }
    assert_response :success
  end

  test 'should get index with valid datetime since parameter' do
    get documents_path, params: { since: '2023-12-01 10:30:00' }
    assert_response :success
  end

  test 'should get index with URL-encoded datetime parameter' do
    get documents_path, params: { since: '2023-12-01%2010%3A30%3A00' }
    assert_response :success
  end

  test 'should get index with URL-encoded RFC 3339 parameter' do
    get documents_path, params: { since: '2023-12-01T10%3A30%3A00%2B00%3A00' }
    assert_response :success
  end

  test 'should return bad request with invalid since parameter' do
    get documents_path, params: { since: 'invalid-date' }
    assert_response :bad_request
    assert_includes response.body, 'Invalid date format'
  end

  test 'should return bad request with malformed since parameter' do
    get documents_path, params: { since: '2023-13-45' }
    assert_response :bad_request
    assert_includes response.body, 'Invalid date format'
  end

  test 'should get index without since parameter' do
    get documents_path
    assert_response :success
  end

  test 'should get index with empty since parameter' do
    get documents_path, params: { since: '' }
    assert_response :success
  end
end
