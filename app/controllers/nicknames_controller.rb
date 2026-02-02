class NicknamesController < ApplicationController
  before_action :authenticate_user!

  def edit
  end

  def update
    if current_user.update(nickname_params)
      redirect_to "/posts", notice: "별명이 성공적으로 변경되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def nickname_params
    params.require(:user).permit(:nickname)
  end
end
