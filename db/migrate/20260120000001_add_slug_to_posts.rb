class AddSlugToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :slug, :string
    add_index :posts, :slug, unique: true
    
    # 기존 데이터에 slug 생성
    reversible do |dir|
      dir.up do
        Post.reset_column_information
        Post.find_each do |post|
          # slug 생성 로직 직접 구현 (모델 메서드 호출 불가)
          # 한글 유지, URL-safe하게 처리
          base_slug = post.title.to_s
            .strip                                    # 앞뒤 공백 제거
            .gsub(/\s+/, '-')                         # 연속된 공백을 하이픈으로
            .gsub(/[^\p{Han}\p{Hangul}\p{Alnum}\-]/, '') # 한글, 영문, 숫자, 하이픈만 유지
            .gsub(/\-+/, '-')                         # 연속된 하이픈을 하나로
            .gsub(/^\-|\-$/, '')                      # 앞뒤 하이픈 제거
          
          base_slug = "post-#{post.id}" if base_slug.blank?
          
          candidate_slug = base_slug
          counter = 1
          
          while Post.where(slug: candidate_slug).where.not(id: post.id).exists?
            counter += 1
            candidate_slug = "#{base_slug}-#{counter}"
          end
          
          post.update_column(:slug, candidate_slug)
        end
      end
    end
  end
end
