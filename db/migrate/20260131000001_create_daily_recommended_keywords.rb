# 매일 추천 키워드 저장 (새 기사 작성기에서 하루 1회 갱신)
class CreateDailyRecommendedKeywords < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_recommended_keywords do |t|
      t.date :date, null: false
      t.text :keywords, null: false # JSON array: ["키워드1", "키워드2", ...]

      t.timestamps
    end

    add_index :daily_recommended_keywords, :date, unique: true
  end
end
