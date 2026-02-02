class MymuseController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  def index
    @page_title = "마이뮤즈 | CharlieK"
    @meta_description = "마이뮤즈 - 코드 진행 추천 및 가사 악보 생성"
    @available_moods = ProgressionService.available_moods
  end

  def create
    unless current_user.can_spend?(1)
      redirect_to mymuse_path, alert: "관리자에게 문의하세요."
      return
    end

    @lyrics = params[:lyrics] || ''
    @mood = params[:mood] || '기쁨'
    @available_moods = ProgressionService.available_moods

    current_user.deduct_coin!(1)

    # 코드 진행 가져오기
    progression_service = ProgressionService.new(@mood)
    @progression = progression_service.progression
    
    # 가사를 마디로 나누기 (줄바꿈 기준)
    @lyrics_lines = @lyrics.split("\n").reject(&:blank?)
    
    respond_to do |format|
      format.turbo_stream
      format.html { render :index }
    end
  end

end
