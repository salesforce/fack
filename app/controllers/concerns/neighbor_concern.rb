module NeighborConcern
  extend ActiveSupport::Concern

  def related_documents(doc)
    related_documents_from_embedding(doc.embedding).offset(1)
  end

  def related_documents_from_embedding(embedding)
    Document.nearest_neighbors(:embedding, embedding, distance: 'euclidean')
  end
end
