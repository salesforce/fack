# frozen_string_literal: true

module NeighborConcern
  extend ActiveSupport::Concern

  def related_documents(doc)
    related_documents_from_embedding(doc.embedding).offset(1)
  end

  def related_documents_from_embedding(embedding)
    Document.nearest_neighbors(:embedding, embedding, distance: 'euclidean')
  end

  # _limit is the number of documents to return.  Returning fewer is better since the most relevant documents are at the top.
  # Because of the ordering, having too many documents may cause the most relevant documents to be lost.
  # TODO implement a better way to get the most relevant documents.
  def related_documents_from_embedding_by_libraries(_embedding, _library_ids, _limit = nil)
    _limit ||= ENV.fetch('RELATED_DOCUMENTS_LIMIT', 25).to_i
    scope = related_documents_from_embedding(_embedding)
    scope = scope.where(library_id: _library_ids) if _library_ids.present?
    scope.order(updated_at: :desc).limit(_limit)
  end
end
