class RenameMusicCategoryToCultureAndAddThoughtsCategory < ActiveRecord::Migration[8.1]
  def up
    # 기존 '음악' 카테고리를 '문화'로 변경
    Post.where(category: '음악').update_all(category: '문화')
    
    # '생각들' 카테고리는 새로운 카테고리이므로 별도 작업 불필요
    # (모델의 CATEGORIES 배열에 이미 추가됨)
  end

  def down
    # 롤백 시 '문화'를 다시 '음악'으로 변경
    Post.where(category: '문화').update_all(category: '음악')
    
    # '생각들' 카테고리의 게시글은 '주식'으로 변경 (롤백 시)
    Post.where(category: '생각들').update_all(category: '주식')
  end
end
