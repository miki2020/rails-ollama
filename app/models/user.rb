class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :affirmations, dependent: :destroy

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_required?
  

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  private
  
  def password_required?
    new_record? || password.present?
  end
end
