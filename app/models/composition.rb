class Composition
  # 8가지 한글 기분에 따른 코드 진행 자료구조
  # C Major 다이아토닉 코드(C, Dm, Em, F, G, Am)만 사용
  # 각 기분마다 2개의 코드 진행 배열 포함
  MOOD_PROGRESSIONS = {
    '기쁨' => [
      ['C', 'F', 'G', 'C'],
      ['C', 'Am', 'F', 'G']
    ],
    '슬픔' => [
      ['Am', 'F', 'C', 'G'],
      ['Am', 'Dm', 'G', 'C']
    ],
    '몽환' => [
      ['F', 'G', 'Em', 'Am'],
      ['C', 'F', 'Am', 'G']
    ],
    '어둠' => [
      ['Am', 'Em', 'F', 'Dm'],
      ['Dm', 'Am', 'Em', 'Am']
    ],
    '희망' => [
      ['C', 'G', 'Am', 'F'],
      ['F', 'G', 'C', 'F']
    ],
    '쓸쓸' => [
      ['Am', 'Em', 'Dm', 'Am'],
      ['C', 'Em', 'Am', 'F']
    ],
    '낭만' => [
      ['F', 'G', 'C', 'Am'],
      ['C', 'Am', 'Dm', 'G']
    ],
    '평온' => [
      ['C', 'Em', 'F', 'G'],
      ['G', 'F', 'C', 'C']
    ]
  }.freeze

  # 기분별 영어 키 매핑 (기존 시스템과의 호환성)
  MOOD_KEY_MAP = {
    '기쁨' => 'happy',
    '슬픔' => 'sad',
    '몽환' => 'dreamy',
    '어둠' => 'dark',
    '희망' => 'hopeful',
    '쓸쓸' => 'lonely',
    '낭만' => 'romantic',
    '평온' => 'peaceful'
  }.freeze

  # 영어 키를 한글로 변환
  def self.mood_to_korean(english_mood)
    MOOD_KEY_MAP.key(english_mood.to_s.downcase) || english_mood
  end

  # 한글 기분을 영어 키로 변환
  def self.korean_to_mood(korean_mood)
    MOOD_KEY_MAP[korean_mood] || korean_mood.to_s.downcase
  end

  # 특정 기분의 코드 진행 가져오기 (랜덤 선택)
  def self.get_progression(mood, index: nil)
    korean_mood = mood.is_a?(String) && MOOD_KEY_MAP.key?(mood) ? mood : mood_to_korean(mood)
    progressions = MOOD_PROGRESSIONS[korean_mood]
    return nil unless progressions

    # index가 지정되면 해당 인덱스 사용, 아니면 랜덤 선택
    selected_index = index || rand(progressions.length)
    progressions[selected_index]
  end

  # 사용 가능한 모든 한글 기분 목록
  def self.available_korean_moods
    MOOD_PROGRESSIONS.keys
  end

  # 사용 가능한 모든 영어 기분 목록
  def self.available_english_moods
    MOOD_KEY_MAP.values
  end
end
