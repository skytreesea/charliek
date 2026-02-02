# 기사 생성 본인만 수정/삭제 가능하도록 user_id 추가
class AddUserIdToArticles < ActiveRecord::Migration[8.1]
  def change
    add_reference :articles, :user, null: true, foreign_key: true
  end
end
