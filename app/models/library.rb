# frozen_string_literal: true

class Library < ApplicationRecord
  include PgSearch::Model

  has_many :documents
  validates :name, presence: true
  belongs_to :user

  has_many :library_users, dependent: :destroy
  has_many :users, through: :library_users

  # Recently viewed items feature
  has_many :viewed_items, as: :viewable, dependent: :destroy

  pg_search_scope :search_by_name,
                  against: %i[name description],
                  using: {
                    tsearch: { prefix: true, dictionary: 'english',
                               tsvector_column: 'search_vector' } # This option allows partial matches
                  }
end
