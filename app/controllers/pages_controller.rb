class PagesController < ApplicationController
  def privacy
    # SEO: Title 설정
    @page_title = "개인정보처리방침 | CharlieK"
    
    # SEO: Description 설정
    @meta_description = "Charlie K Archive의 개인정보처리방침을 확인하세요."
    
    # Open Graph 메타 태그 설정
    @og_title = @page_title
    @og_description = @meta_description
    @og_url = "#{request.base_url}#{request.path}"
  end
end
