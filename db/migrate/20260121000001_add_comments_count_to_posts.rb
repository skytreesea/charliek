class AddCommentsCountToPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :posts, :comments_count, :integer, default: 0, null: false
    
    # 기존 댓글 개수 업데이트 (SQL로 직접 계산하여 효율적으로 처리)
    execute <<-SQL
      UPDATE posts
      SET comments_count = (
        SELECT COUNT(*)
        FROM comments
        WHERE comments.post_id = posts.id
      )
    SQL
  end

  def down
    remove_column :posts, :comments_count
  end
end
