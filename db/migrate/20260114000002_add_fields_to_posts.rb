class AddFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :views_count, :integer, default: 0, null: false
    add_column :posts, :likes_count, :integer, default: 0, null: false
    add_reference :posts, :user, null: true, foreign_key: true
  end
end
