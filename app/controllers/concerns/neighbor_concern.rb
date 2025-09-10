# frozen_string_literal: true

module NeighborConcern
  extend ActiveSupport::Concern

  def related_documents(doc)
    related_documents_from_embedding(doc.embedding).offset(1)
  end

  def related_documents_from_embedding(embedding)
    Document.nearest_neighbors(:embedding, embedding, distance: 'euclidean')
  end

  # Delegate to the Document model scope for better organization
  def related_documents_from_embedding_by_libraries(_embedding, __limit = nil)
    Document.related_by_embedding(_embedding, limit: _limit)
  end
end
