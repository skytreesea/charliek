class AddIndexesToPosts < ActiveRecord::Migration[8.1]
  def change
    add_index :posts, :created_at
    add_index :posts, :views_count
  end
end
