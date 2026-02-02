# 기사생성기 (development 전용)
class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.text :content
      t.string :keywords
      t.text :prompt_used

      t.timestamps
    end

    add_index :articles, :created_at
  end
end
