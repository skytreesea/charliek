# Devise 회원가입 후 메인으로 이동 + 10냥 환영 팝업
class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(_resource)
    flash[:welcome_coins] = true
    root_path
  end
end
