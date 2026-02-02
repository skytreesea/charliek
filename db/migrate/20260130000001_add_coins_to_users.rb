# 냥(코인) 시스템: 가입 시 10냥 지급, 마이뮤즈/기사 생성 시 1냥 차감. 수퍼관리자는 무한.
class AddCoinsToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :coins, :integer, default: 10, null: false
  end

  def down
    remove_column :users, :coins
  end
end
