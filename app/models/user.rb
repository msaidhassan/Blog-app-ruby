class User < ApplicationRecord
  has_secure_password
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one_attached :image

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  validate :correct_image_type  

  def admin?
    admin
  end

  def image_url
    image.attached? ? "/api/v1/users/#{id}/image" : nil
  end

  def as_json(options = {})
    super(options.merge(
      except: [:password_digest, :admin],
      methods: [:image_url]
    ))
  end

  private

  def correct_image_type
    if image.attached? && !image.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:image, ' Image must be a JPEG, PNG, or GIF')
    end
  end
end