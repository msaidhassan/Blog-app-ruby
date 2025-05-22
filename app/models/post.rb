class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  
  validates :title, presence: true
  validates :body, presence: true
  validate :has_at_least_one_tag
  
  private
  
  def has_at_least_one_tag
    if tags.empty?
      errors.add(:tags, "must have at least one tag")
    end
  end
end