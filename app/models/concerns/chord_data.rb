module ChordData
  # C Major Key의 다이아토닉 코드 데이터
  # 타브 배열은 [6th string, 5th string, 4th string, 3rd string, 2nd string, 1st string] 순서
  # nil은 해당 줄을 연주하지 않음을 의미
  
  C_MAJOR_CHORDS = {
    'C' => {
      name: 'C',
      tabs: [nil, 3, 2, 0, 1, 0]  # C Major
    },
    'Dm' => {
      name: 'Dm',
      tabs: [nil, nil, 0, 2, 3, 1]  # D Minor
    },
    'Em' => {
      name: 'Em',
      tabs: [0, 2, 2, 0, 0, 0]  # E Minor
    },
    'F' => {
      name: 'F',
      tabs: [1, 3, 3, 2, 1, 1]  # F Major (바레 코드)
    },
    'G' => {
      name: 'G',
      tabs: [3, 2, 0, 0, 3, 3]  # G Major
    },
    'Am' => {
      name: 'Am',
      tabs: [nil, 0, 2, 2, 1, 0]  # A Minor
    },
    'Em7' => {
      name: 'Em7',
      tabs: [0, 2, 0, 0, 0, 0]  # E Minor 7th
    },
    'Fmaj7' => {
      name: 'Fmaj7',
      tabs: [nil, 3, 2, 0, 0, 0]  # F Major 7th
    },
    'E' => {
      name: 'E',
      tabs: [0, 2, 2, 1, 0, 0]  # E Major
    }
  }.freeze
  
  # 모든 코드 이름 배열
  def self.chord_names
    C_MAJOR_CHORDS.keys
  end
  
  # 특정 코드 데이터 가져오기
  def self.chord(name)
    C_MAJOR_CHORDS[name]
  end
  
  # 모든 코드 데이터 가져오기
  def self.all_chords
    C_MAJOR_CHORDS
  end
end
