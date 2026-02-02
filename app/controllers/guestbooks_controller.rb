class GuestbooksController < ApplicationController
  before_action :authenticate_user!, only: [:destroy]
  before_action :check_admin, only: [:destroy]
  
  def index
    @guestbook = Guestbook.new
    @guestbooks = Guestbook.recent.limit(50)
  end
  
  def create
    @guestbook = Guestbook.new(guestbook_params)
    
    if @guestbook.save
      redirect_to guestbooks_path, notice: "방명록이 등록되었습니다."
    else
      @guestbooks = Guestbook.recent.limit(50)
      render :index, status: :unprocessable_entity
    end
  end
  
  def destroy
    @guestbook = Guestbook.find(params[:id])
    @guestbook.destroy
    redirect_to guestbooks_path, notice: "방명록이 삭제되었습니다."
  end
  
  private
  
  def guestbook_params
    params.require(:guestbook).permit(:name, :content)
  end
  
  def check_admin
    unless current_user&.admin?
      redirect_to guestbooks_path, alert: "관리자만 삭제할 수 있습니다.", status: :forbidden
    end
  end
end
