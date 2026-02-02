# Gemini API 호출 서비스 (기사생성기)
# API 키: ENV['GEMINI_API_KEY']
# Net::HTTP로 REST API 직접 호출 (표준 라이브러리만 사용)
# 실패 시 항상 Exception(MissingApiKey/ApiError)을 raise함. 문자열·해시 반환 없음 (Rails.error.report 호환)
require "net/http"
require "uri"
require "json"

class GeminiService
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
  # supportedGenerationMethods에 "generateContent"가 있는 모델만 사용 가능
  # 목록: curl "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY"
  DEFAULT_MODEL = "gemini-2.0-flash"

  class Error < StandardError; end
  class MissingApiKey < Error; end
  class ApiError < Error; end

  def initialize(api_key: nil)
    @api_key = api_key.presence || ENV["GEMINI_API_KEY"].presence
    # development: 서버가 다른 cwd에서 떠서 .env를 못 읽었을 수 있음 → 한 번 더 로드
    if @api_key.blank? && Rails.env.development?
      load_dotenv
      @api_key = ENV["GEMINI_API_KEY"].presence
    end
  end

  # 사용자가 입력한 keywords를 받아 선택한 문체로 글 생성
  # @param keywords [String] 쉼표 등으로 구분된 키워드
  # @param writing_style [String] 문체 (official, news, blog, essay, novelist)
  # @param selected_title [String] 선택한 제목 (제목만 생성할 때는 nil)
  # @return [Hash] { title:, content:, prompt_used: }
  def generate_article(keywords, writing_style: "official", selected_title: nil)
    if @api_key.blank? && Rails.env.development?
      load_dotenv
      @api_key = ENV["GEMINI_API_KEY"].presence
    end
    raise MissingApiKey, missing_api_key_message if @api_key.blank?

    prompt = build_prompt(keywords, writing_style: writing_style, selected_title: selected_title)
    response = call_api(prompt)

    parse_article_response(response, prompt)
  end

  # 제목 3개 생성
  # @param keywords [String] 쉼표 등으로 구분된 키워드
  # @param writing_style [String] 문체 (official, news, blog, essay, novelist)
  # @return [Array<String>] 제목 3개 배열
  def generate_titles(keywords, writing_style: "official")
    if @api_key.blank? && Rails.env.development?
      load_dotenv
      @api_key = ENV["GEMINI_API_KEY"].presence
    end
    raise MissingApiKey, missing_api_key_message if @api_key.blank?

    prompt = build_title_prompt(keywords, writing_style: writing_style)
    response = call_api(prompt)

    parse_titles_response(response)
  end

  private

  def load_dotenv
    path = Rails.root.join(".env")
    return unless path.exist?
    require "dotenv"
    Dotenv.load(path)
  end

  def missing_api_key_message
    if Rails.env.production?
      "GEMINI_API_KEY가 서버에 설정되지 않았습니다. Fly 배포 시: fly secrets set GEMINI_API_KEY=키 를 설정한 뒤 앱을 재시작해 주세요."
    else
      "GEMINI_API_KEY 환경변수가 설정되지 않았습니다. .env에 GEMINI_API_KEY=키 를 넣고 서버를 재시작해보세요."
    end
  end

  def build_prompt(keywords, writing_style: "official", selected_title: nil)
    k = keywords.to_s.strip.presence || "일반"
    style_label = { "official" => "공식문서", "news" => "신문기사", "blog" => "블로그", "essay" => "에세이", "novelist" => "소설가" }[writing_style.to_s] || "공식문서"

    lines = []
    lines << "[선택된 문체: #{style_label}] 이 문체를 반드시 유지하여 작성하세요."
    lines << ""
    if writing_style.to_s == "novelist"
      # 소설가: 프롬프트에 톤을 명시적으로 고정
      lines << "[필수] 당신은 소설가입니다. 신문 기자나 공식 문서 작성자가 아닙니다. 문체는 반드시 소설/문학 작품 톤이어야 합니다."
      lines << ""
      lines << "다음 사항을 지킨 채 글을 작성하세요:"
      lines << "- 공식문서·보도자료·뉴스 기사 톤을 사용하지 마세요. 객관적 보도체, '-다/-한다' 종결, 격식체를 쓰지 마세요."
      lines << "- 소설처럼 서사·묘사·감정·분위기를 살리세요. 구체적인 장면, 이미지, 인물의 시선이나 내면을 담을 수 있습니다."
      lines << "- 문학적 문장(비유, 리듬, 함축)을 사용하고, 독자가 이야기 속에 들어온 느낌이 나도록 쓰세요."
      lines << ""
      if selected_title.present?
        lines << "제목: #{selected_title}"
      else
        lines << "첫 줄: 이 글에 어울리는 제목 한 줄만 작성 (따옴표 없이). 소설/작품 제목처럼 문학적으로."
        lines << "이어서: 빈 줄 하나 둔 뒤 본문."
      end
      lines << "본문: 2~4문단. **Markdown** 사용 가능(굵게, 리스트 등). 한국어."
      lines << ""
      lines << "키워드: #{k}"
    else
      style_descs = {
        "official" => "공식문서 스타일 (정확하고 객관적, 공식적이고 전문적인 톤)",
        "news" => "신문기사 스타일 (객관적이고 사실 중심, 5W1H를 명확히 제시, 전문적이고 중립적인 톤)",
        "blog" => "블로그 글 스타일 (친근하고 읽기 쉬운 톤, 개인적인 경험과 의견 포함 가능)",
        "essay" => "에세이 스타일 (사색적이고 문학적, 깊이 있는 사고와 표현)"
      }
      style_desc = style_descs[writing_style.to_s] || style_descs["official"]

      if selected_title.present?
        lines << "다음 제목과 키워드를 바탕으로 #{style_desc}로 글을 작성해주세요."
        lines << ""
        lines << "제목: #{selected_title}"
      else
        lines << "다음 키워드를 바탕으로 #{style_desc}로 글을 작성해주세요."
        lines << "- 첫 줄: 기사 제목만 작성 (따옴표 없이)"
      end
      lines << "- 빈 줄 하나"
      lines << "- 이어서 본문 작성 (2~4문단). 본문은 **Markdown** 형식(굵게, 링크, 리스트 등)을 사용해주세요."
      lines << "- 한국어로 작성"
      lines << ""
      lines << "키워드: #{k}"
    end

    lines.join("\n")
  end

  def build_title_prompt(keywords, writing_style: "official")
    k = keywords.to_s.strip.presence || "일반"
    style_label = { "official" => "공식문서", "news" => "신문기사", "blog" => "블로그", "essay" => "에세이", "novelist" => "소설가" }[writing_style.to_s] || "공식문서"

    if writing_style.to_s == "novelist"
      return [
        "[선택된 문체: 소설가] 제목은 반드시 소설/문학 작품 스타일로만 작성하세요.",
        "[필수] 소설가가 쓴 소설·단편·장편의 제목처럼 작성하세요. 신문 헤드라인, 보도자료, 공식문서 제목 스타일은 사용하지 마세요.",
        "",
        "다음 키워드를 소재로, 문학 작품 제목 3개를 만드세요:",
        "- 각 제목은 시적이거나, 한 장면·한 순간을 떠올리게 하거나, 감정·분위기가 느껴지도록 작성.",
        "- 예시 느낌: '그날 밤', '빗속의 편지', '마지막 잎새'처럼 소설/문학 제목 톤.",
        "- 뉴스처럼 '~동향', '~분석', '~전망' 같은 표현 금지. 보고서형 문장 금지.",
        "",
        "제목만 정확히 3개, 한 줄에 하나씩. 번호·기호 없이. 한국어.",
        "",
        "키워드: #{k}"
      ].join("\n")
    end

    style_instructions = {
      "official" => "공식문서 스타일의 제목을 작성해주세요. 정확하고 간결하며 전문적인 톤으로, 보고서나 공문 제목처럼 보여야 합니다.",
      "news" => "신문기사 스타일의 제목을 작성해주세요. 사실을 압축한 헤드라인처럼, 5W1H가 드러나고 객관적·중립적인 톤으로 작성합니다.",
      "blog" => "블로그 글 스타일의 제목을 작성해주세요. 궁금증을 유발하거나 친근하게 끌어당기는 톤으로, 클릭하고 싶은 제목이어야 합니다.",
      "essay" => "에세이 스타일의 제목을 작성해주세요. 사색적이고 문학적이며, 주제를 함축적으로 드러내는 제목으로 작성합니다."
    }
    instruction = style_instructions[writing_style.to_s] || style_instructions["official"]

    [
      "[선택된 문체: #{style_label}]",
      "다음 키워드를 바탕으로 #{instruction}",
      "",
      "제목을 정확히 3개만 작성하고, 각 제목은 한 줄에 하나씩만 써주세요. 번호나 기호는 붙이지 마세요. 한국어로만 작성합니다.",
      "",
      "키워드: #{k}"
    ].join("\n")
  end

  def call_api(prompt)
    url = [BASE_URL, "models", "#{DEFAULT_MODEL}:generateContent"].join("/")
    url += "?key=#{ERB::Util.url_encode(@api_key)}"
    uri = URI.parse(url)
    body = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 2048,
        topP: 0.95
      }
    }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 60
    req = Net::HTTP::Post.new(uri.request_uri)
    req["Content-Type"] = "application/json"
    req.body = body

    res = http.request(req)

    unless res.is_a?(Net::HTTPSuccess)
      parsed = (res.body.present? ? JSON.parse(res.body) : {}) rescue {}
      msg = parsed.dig("error", "message").presence || res.body.to_s.presence || "Unknown error"
      raise ApiError, "Gemini API 오류 (#{res.code}): #{msg}"
    end

    parsed = (res.body.present? ? JSON.parse(res.body) : {}) rescue {}
    raise ApiError, "Gemini API가 올바른 JSON을 반환하지 않았습니다." if parsed.blank?

    parsed
  end

  def parse_article_response(body, prompt_used)
    text = body.dig("candidates", 0, "content", "parts", 0, "text")
    raise ApiError, "Gemini API가 본문을 반환하지 않았습니다." if text.blank?

    text = text.strip
    lines = text.split("\n")
    title = lines.first.to_s.strip.presence || "제목 없음"
    content = lines[1..].join("\n").strip.presence || text

    { title: title, content: content, prompt_used: prompt_used }
  end

  def parse_titles_response(body)
    text = body.dig("candidates", 0, "content", "parts", 0, "text")
    raise ApiError, "Gemini API가 제목을 반환하지 않았습니다." if text.blank?

    titles = text.strip.split("\n").map(&:strip).reject(&:blank?).first(3)
    raise ApiError, "제목이 3개 생성되지 않았습니다." if titles.size < 3

    titles
  end

  # 수정된 프롬프트로 직접 기사 생성 (재생성용)
  def generate_article_with_custom_prompt(custom_prompt)
    if @api_key.blank? && Rails.env.development?
      load_dotenv
      @api_key = ENV["GEMINI_API_KEY"].presence
    end
    raise MissingApiKey, missing_api_key_message if @api_key.blank?

    response = call_api(custom_prompt)
    text = response.dig("candidates", 0, "content", "parts", 0, "text")
    raise ApiError, "Gemini API가 본문을 반환하지 않았습니다." if text.blank?

    content = text.strip
    { content: content, prompt_used: custom_prompt }
  end
end
