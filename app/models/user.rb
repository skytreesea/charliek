class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, {
    normal: 'normal',           # 일반
    admin: 'admin',             # 관리자
    super_admin: 'super_admin'  # 수퍼관리자
  }

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :articles, dependent: :nullify

  def liked?(post)
    likes.exists?(post_id: post.id)
  end

  def display_name
    return nickname if nickname.present?
    
    # 이메일을 sk*** 형태로 변환
    email_part = email.split('@').first
    return "#{email_part[0, 2]}***" if email_part.length >= 2
    return "#{email_part[0]}***" if email_part.length >= 1
    "익명"
  end

  # enum이 admin? 메서드를 자동 생성하지만, 우리가 정의한 메서드가 이를 덮어씀
  # 관리자(admin) 또는 수퍼관리자(super_admin)인지 확인
  def admin?
    role == 'admin' || role == 'super_admin'
  end

  # 수퍼관리자인지 확인 (enum에서 자동 생성되지만 명시적으로 정의)
  def super_admin?
    role == 'super_admin'
  end

  def role_display_name
    case role
    when 'normal'
      '일반'
    when 'admin'
      '관리자'
    when 'super_admin'
      '수퍼관리자'
    else
      '일반'
    end
  end

  # 냥(코인): 수퍼관리자는 무한, 그 외에는 coins 컬럼 값 (컬럼 없으면 0)
  def coins_display
    return "∞" if super_admin?
    return "0" unless self.class.column_names.include?("coins")
    (read_attribute(:coins) || 0).to_s
  end

  # amount 냥 사용 가능한지 (수퍼관리자는 항상 가능)
  def can_spend?(amount = 1)
    return true if super_admin?
    return false unless self.class.column_names.include?("coins")
    (read_attribute(:coins) || 0) >= amount
  end

  # amount 냥 차감. 수퍼관리자는 차감하지 않음. 성공 시 true
  def deduct_coin!(amount = 1)
    return true if super_admin?
    return false unless self.class.column_names.include?("coins")
    return false if (read_attribute(:coins) || 0) < amount
    update_column(:coins, read_attribute(:coins) - amount)
  end
end
