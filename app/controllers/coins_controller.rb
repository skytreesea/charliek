# 코인 구매 (결제 연동 예정)
# 나중에 결제(토스, 스트라이프 등) 연동 시 이 컨트롤러에서 처리
class CoinsController < ApplicationController
  before_action :authenticate_user!

  def index
    @page_title = "코인 구매 | CharlieK"
    @meta_description = "냥(코인) 구매 - 마이뮤즈, 기사생성기 이용에 사용됩니다."
  end
end
