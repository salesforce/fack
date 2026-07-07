# frozen_string_literal: true

require 'test_helper'

# Regression coverage for PG::AmbiguousColumn on the documents index.
#
# The index eager-loads :library and :user. When those associations are
# forced into the query as JOINs (e.g. by materializing similarity results
# with pluck) *and* a date filter references `updated_at`, an unqualified
# `updated_at` is ambiguous because documents, libraries, and users all have
# that column. The filter must qualify the column as `documents.updated_at`.
class DocumentSimilarityFilterTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @library = libraries(:one)
    Document.create!(
      title: 'Similarity Doc',
      document: 'similarity content',
      library: @library,
      user: @user,
      embedding: Array.new(1536, 0.1)
    )
  end

  # Mirrors the controller's similar_to path: eager-loaded associations, a
  # `since` date filter, nearest-neighbor ordering, then materialization.
  # `eager_load` forces the LEFT OUTER JOINs that make a bare `updated_at`
  # ambiguous.
  def materialized_ids_with(updated_at_predicate)
    Document
      .eager_load(:library, :user)
      .where(library_id: @library.id)
      .where(updated_at_predicate, '2000-01-01')
      .related_by_embedding(Array.new(1536, 0.1))
      .pluck(:id)
  end

  test 'qualified documents.updated_at filter does not raise ambiguous column' do
    assert_nothing_raised do
      materialized_ids_with('documents.updated_at > ?')
    end
  end

  test 'unqualified updated_at filter is ambiguous when associations are joined' do
    # Guards that the scenario is real: without qualification Postgres raises.
    error = assert_raises(ActiveRecord::StatementInvalid) do
      materialized_ids_with('updated_at > ?')
    end
    assert_match(/ambiguous/i, error.message)
  end
end
