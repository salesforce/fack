# frozen_string_literal: true

class Library < ApplicationRecord
  has_many :documents
  validates :name, presence: true
  belongs_to :user

  has_many :library_users, dependent: :destroy
  has_many :users, through: :library_users
end
