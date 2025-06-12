# frozen_string_literal: true

module NeighborConcern
  extend ActiveSupport::Concern

  def related_documents(doc)
    related_documents_from_embedding(doc.embedding).offset(1)
  end

  def related_documents_from_embedding(embedding)
    Document.nearest_neighbors(:embedding, embedding, distance: 'euclidean')
  end

  def related_documents_from_embedding_by_libraries(_embedding, _library_ids)
    scope = related_documents_from_embedding(_embedding)
    scope = scope.where(library_id: _library_ids) if _library_ids.present?
    scope.order(created_at: :desc).limit(100)
  end
end
