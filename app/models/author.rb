class Author < ApplicationRecord
  include Statusable

  has_many :collection_authors
  has_many :collections, through: :collection_authors

  scope :ordered, -> { order(:name_ka) }
end
