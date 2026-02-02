class ProgressionService
  # 분위기별 한글 이름 매핑
  MOOD_NAMES = {
    'happy' => '기쁨',
    'sad' => '슬픔',
    'dreamy' => '몽환',
    'dark' => '어둠',
    'hopeful' => '희망',
    'lonely' => '쓸쓸',
    'romantic' => '낭만',
    'peaceful' => '평온',
    '기쁨' => '기쁨',
    '슬픔' => '슬픔',
    '몽환' => '몽환',
    '어둠' => '어둠',
    '희망' => '희망',
    '쓸쓸' => '쓸쓸',
    '낭만' => '낭만',
    '평온' => '평온'
  }.freeze

  def initialize(mood, progression_index: nil)
    # 한글 기분은 그대로 유지, 영어 기분은 소문자로 변환
    @mood = mood.to_s
    @mood = @mood.downcase unless @mood.match?(/[\uAC00-\uD7A3]/) # 한글이 아니면 downcase
    @progression_index = progression_index
  end

  # 선택한 분위기에 맞는 코드 진행 반환
  def progression
    # Composition 모델의 새로운 자료구조 사용
    korean_mood = MOOD_NAMES[@mood] || @mood
    
    # 한글 기분이 Composition에 있는지 확인
    chord_names = if Composition::MOOD_PROGRESSIONS.key?(korean_mood)
      # Composition 모델에서 가져오기 (랜덤 또는 지정된 인덱스)
      Composition.get_progression(korean_mood, index: @progression_index)
    else
      # 기존 영어 기분을 한글로 변환 시도
      english_mood = Composition.korean_to_mood(korean_mood)
      Composition.get_progression(english_mood, index: @progression_index)
    end

    return nil unless chord_names

    chord_names.map do |chord_name|
      chord_data = ChordData.chord(chord_name)
      if chord_data
        {
          name: chord_data[:name],
          tabs: chord_data[:tabs]
        }
      else
        # 코드 데이터가 없으면 이름만 반환
        {
          name: chord_name,
          tabs: nil
        }
      end
    end
  end

  # 분위기 이름 반환 (한글)
  def mood_name
    MOOD_NAMES[@mood] || @mood.capitalize
  end

  # 사용 가능한 모든 분위기 목록 반환 (한글)
  def self.available_moods
    Composition.available_korean_moods
  end

  # 특정 분위기의 코드 진행 가져오기 (클래스 메서드)
  def self.get_progression(mood, progression_index: nil)
    new(mood, progression_index: progression_index).progression
  end

  # 특정 분위기의 코드 이름 배열만 가져오기
  def self.get_chord_names(mood, progression_index: nil)
    korean_mood = MOOD_NAMES[mood.to_s.downcase] || mood
    Composition.get_progression(korean_mood, index: progression_index)
  end
end
