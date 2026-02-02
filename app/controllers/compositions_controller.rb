class CompositionsController < ApplicationController
  def index
    @available_moods = Composition.available_korean_moods
  end

  def create
    mood = params[:mood] || '기쁨'
    
    # Composition::MOOD_PROGRESSIONS에서 해당 기분 찾기
    progressions = Composition::MOOD_PROGRESSIONS[mood]
    
    # 해당 기분이 없으면 기본값으로 '기쁨'의 첫 번째 진행 사용
    if progressions.nil? || progressions.empty?
      progressions = Composition::MOOD_PROGRESSIONS['기쁨']
      selected_chords = progressions[0] # 첫 번째 진행 사용
    else
      # 2개의 진행 중 하나를 샘플링
      selected_chords = progressions.sample
    end
    
    # @composition.chords에 할당
    @composition = OpenStruct.new(chords: selected_chords, mood: mood)
    
    # 응답 처리
    respond_to do |format|
      format.json { render json: @composition }
      format.html { render :show }
    end
  end
end
