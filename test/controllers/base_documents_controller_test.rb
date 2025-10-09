# frozen_string_literal: true

require 'test_helper'

class BaseDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
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

  test 'should show only active documents by default' do
    active_doc = Document.create!(title: 'Active', document: 'active content', library: libraries(:one), user: @user)
    deleted_doc = Document.create!(title: 'Deleted', document: 'deleted content', library: libraries(:one), user: @user)
    deleted_doc.soft_delete!

    get documents_path
    assert_response :success
    assert_includes assigns(:documents), active_doc
    assert_not_includes assigns(:documents), deleted_doc
  end

  test 'should show both active and deleted documents when show_deleted=true' do
    active_doc = Document.create!(title: 'Active 2', document: 'active content 2', library: libraries(:one), user: @user)
    deleted_doc = Document.create!(title: 'Deleted 2', document: 'deleted content 2', library: libraries(:one), user: @user)
    deleted_doc.soft_delete!

    get documents_path, params: { show_deleted: 'true' }
    assert_response :success
    assert_includes assigns(:documents), active_doc
    assert_includes assigns(:documents), deleted_doc
  end

  test 'should show only deleted documents when show_deleted=only' do
    active_doc = Document.create!(title: 'Active 3', document: 'active content 3', library: libraries(:one), user: @user)
    deleted_doc = Document.create!(title: 'Deleted 3', document: 'deleted content 3', library: libraries(:one), user: @user)
    deleted_doc.soft_delete!

    get documents_path, params: { show_deleted: 'only' }
    assert_response :success
    assert_not_includes assigns(:documents), active_doc
    assert_includes assigns(:documents), deleted_doc
  end
end
