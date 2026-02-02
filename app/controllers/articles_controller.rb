# 기사생성기 컨트롤러 (production 배포 가능)
# 페이지네이션은 ApplicationController의 Pagy::Method 사용
class ArticlesController < ApplicationController
  include ArticlesHelper

  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :authorize_article_owner!, only: [:edit, :update, :destroy]

  def index
    @pagy, @articles = pagy(Article.recent, items: 10)
  rescue ActiveRecord::StatementInvalid => e
    raise unless e.message.to_s.include?("Could not find table") || e.message.to_s.include?("no such table")
    redirect_to root_path, alert: "기사생성기 데이터베이스가 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요."
  end

  def show
  end

  def new
    @article = Article.new
  end

  def create
    # 미리보기에서 "저장" 클릭 시 실제 저장 (1냥 차감)
    if params[:save_preview].present?
      unless user_signed_in?
        redirect_to new_user_session_path, alert: "로그인이 필요합니다."
        return
      end
      unless current_user.can_spend?(1)
        redirect_to new_article_path, alert: "관리자에게 문의하세요."
        return
      end
      @article = Article.new(article_params)
      @article.user_id = current_user.id
      if @article.save
        current_user.deduct_coin!(1)
        flash[:coin_used] = true
        redirect_to @article, notice: "기사가 저장되었습니다."
      else
        render :preview, status: :unprocessable_entity
      end
      return
    end

    # 재생성 요청 (프롬프트 수정 후, 1냥 차감)
    if params[:regenerate].present?
      unless user_signed_in?
        redirect_to new_user_session_path, alert: "로그인이 필요합니다."
        return
      end
      unless current_user.can_spend?(1)
        redirect_to new_article_path, alert: "관리자에게 문의하세요."
        return
      end

      keywords = params.dig(:article, :keywords).to_s.strip
      writing_style = params.dig(:article, :writing_style).to_s.presence || "official"
      selected_title = params.dig(:article, :selected_title).to_s.strip
      modified_prompt = params.dig(:article, :prompt_used).to_s.strip

      if selected_title.blank?
        @article = Article.new(keywords: keywords, writing_style: writing_style)
        @article.errors.add(:base, "제목이 필요합니다.")
        return render :preview, status: :unprocessable_entity
      end

      current_user.deduct_coin!(1)
      @coin_used = true

      # 수정된 프롬프트로 직접 API 호출
      result = GeminiService.new.generate_article_with_custom_prompt(modified_prompt)
      @article = Article.new(
        title: selected_title,
        content: result[:content],
        keywords: keywords,
        prompt_used: modified_prompt,
        writing_style: writing_style
      )
      render :preview
      return
    end

    # 제목 선택 후 기사 생성
    if params[:selected_title].present?
      keywords = params.dig(:article, :keywords).to_s.strip
      writing_style = params.dig(:article, :writing_style).to_s.presence || "official"
      selected_title = params.dig(:article, :selected_title).to_s.strip

      if selected_title.blank?
        @article = Article.new(keywords: keywords, writing_style: writing_style)
        @article.errors.add(:base, "제목을 선택해주세요.")
        return render :title_selection, status: :unprocessable_entity
      end

      result = GeminiService.new.generate_article(keywords, writing_style: writing_style, selected_title: selected_title)
      @article = Article.new(
        title: selected_title,
        content: result[:content],
        keywords: keywords,
        prompt_used: result[:prompt_used],
        writing_style: writing_style
      )
      render :preview
      return
    end

    # 첫 생성: 제목 3개 생성
    keywords = params.dig(:article, :keywords).to_s.strip
    writing_style = params.dig(:article, :writing_style).to_s.presence || "official"
    # 문체가 전달되는지 확인 (development에서만 로그)
    Rails.logger.info "[Articles#create] writing_style=#{writing_style.inspect} (params[:article][:writing_style]=#{params.dig(:article, :writing_style).inspect})" if Rails.env.development?

    if keywords.blank?
      @article = Article.new(keywords: keywords, writing_style: writing_style)
      @article.errors.add(:keywords, "를 입력해주세요.")
      return render_form_frame(422)
    end

    list = keyword_list(keywords)
    if list.size < 2
      @article = Article.new(keywords: keywords, writing_style: writing_style)
      @article.errors.add(:keywords, "키워드는 최소 2개 이상 입력해 주세요.")
      return render_form_frame(422)
    end
    if list.size > 6
      @article = Article.new(keywords: keywords, writing_style: writing_style)
      @article.errors.add(:keywords, "키워드는 6개 이하여야 합니다.")
      return render_form_frame(422)
    end

    # 제목 3개 생성
    titles = GeminiService.new.generate_titles(keywords, writing_style: writing_style)
    @article = Article.new(keywords: keywords, writing_style: writing_style)
    @titles = titles
    render :title_selection
  rescue SystemExit, SignalException
    raise
  rescue Exception => e
    # Rails.error.report에는 반드시 Exception 인스턴스만 전달되어야 함.
    # create에서 예외를 여기서 처리하고 응답만 반환하면 executor로 예외가 전달되지 않음.
    begin
      msg = e.respond_to?(:message) ? e.message.to_s : e.to_s
      safe_msg = msg.to_s.byteslice(0, 500).to_s
      html = "<!DOCTYPE html><html><head><meta charset=\"utf-8\"></head><body style=\"font-family:sans-serif;padding:2rem;\"><p style=\"color:#b91c1c;\">오류: #{ERB::Util.html_escape(safe_msg)}</p><p><a href=\"#{new_article_path}\">새 기사 작성으로 돌아가기</a></p></body></html>"
      return render html: html.html_safe, status: 422, content_type: "text/html"
    rescue Exception
      return render plain: "오류가 발생했습니다. 새 기사 작성: #{new_article_path}", status: 422
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to @article, notice: "기사가 성공적으로 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_url, notice: "기사가 삭제되었습니다."
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :content, :keywords, :prompt_used, :writing_style)
  end

  def render_form_frame(status)
    render partial: "articles/form_frame_content",
           locals: { article: @article },
           layout: false,
           status: status
  end

  # 본인 기사 또는 수퍼관리자는 수정/삭제 가능
  def authorize_article_owner!
    return if current_user&.super_admin?
    return if @article.owned_by?(current_user)
    redirect_to articles_path, alert: "본인이 작성한 기사만 수정·삭제할 수 있습니다."
  end
end
