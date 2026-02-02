class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_super_admin

  def index
    @users = User.where.not(role: 'super_admin').order(created_at: :desc)
  end

  def update_roles
    user_ids = params[:user_ids] || []
    role = params[:role]

    if role.present? && ['normal', 'admin'].include?(role)
      updated_count = 0
      User.where(id: user_ids).find_each do |user|
        # 수퍼관리자는 변경할 수 없음
        next if user.role == 'super_admin' || user.super_admin?
        user.update(role: role)
        updated_count += 1
      end
      redirect_to "/admin/users", notice: "#{updated_count}명의 사용자 역할이 업데이트되었습니다."
    else
      redirect_to "/admin/users", alert: "잘못된 요청입니다."
    end
  end

  def update_roles_batch
    # Strong Parameters 허용
    permitted_params = params.permit(changes: [:user_id, :role])
    changes = permitted_params[:changes] || []
    
    Rails.logger.debug "Changes param: #{changes.inspect}"
    Rails.logger.debug "Changes type: #{changes.class}"
    
    # 배열로 변환 (Rails가 해시로 받은 경우 대비)
    if changes.is_a?(ActionController::Parameters) || changes.is_a?(Hash)
      changes_array = []
      changes.each do |key, value|
        if value.is_a?(ActionController::Parameters) || value.is_a?(Hash)
          changes_array << value.to_h.symbolize_keys
        end
      end
      changes = changes_array
    elsif changes.is_a?(Array)
      # 배열인 경우 각 항목을 해시로 변환
      changes = changes.map do |item|
        if item.is_a?(ActionController::Parameters)
          item.to_h.symbolize_keys
        elsif item.is_a?(Hash)
          item.symbolize_keys
        else
          item
        end
      end
    end
    
    unless changes.is_a?(Array) && changes.any?
      Rails.logger.debug "No valid changes found"
      render json: { success: false, error: '변경할 내용이 없습니다.' }, status: :bad_request
      return
    end
    
    updated_count = 0
    errors = []
    
    changes.each_with_index do |change, idx|
      # 이미 symbolize_keys로 변환했으므로 심볼 키로 접근
      user_id = change[:user_id]
      role = change[:role]
      
      Rails.logger.debug "Processing change #{idx}: user_id=#{user_id}, role=#{role}, change=#{change.inspect}"
      
      unless user_id.present? && role.present? && ['normal', 'admin'].include?(role.to_s)
        errors << "잘못된 요청: user_id=#{user_id}, role=#{role}"
        next
      end
      
      user = User.find_by(id: user_id.to_i)
      unless user
        errors << "사용자를 찾을 수 없습니다: user_id=#{user_id}"
        next
      end
      
      # 수퍼관리자는 변경할 수 없음
      if user.role == 'super_admin' || user.super_admin?
        errors << "수퍼관리자는 변경할 수 없습니다: #{user.email}"
        next
      end
      
      # 이미 같은 역할이면 건너뛰기
      if user.role == role.to_s
        Rails.logger.debug "User #{user.id} already has role #{role}, skipping"
        next
      end
      
      if user.update(role: role.to_s)
        updated_count += 1
        Rails.logger.debug "Updated user #{user.id} to role #{role}"
      else
        errors << "#{user.email}: #{user.errors.full_messages.join(', ')}"
      end
    end
    
    Rails.logger.debug "Final result: updated_count=#{updated_count}, errors=#{errors.inspect}"
    
    if updated_count > 0
      render json: { success: true, updated_count: updated_count, errors: errors.presence }
    elsif errors.any?
      render json: { success: false, error: errors.join('; ') }, status: :unprocessable_entity
    else
      render json: { success: false, error: '변경할 내용이 없습니다.' }, status: :bad_request
    end
  end

  def update_role
    user_id = params[:user_id]
    role = params[:role]

    unless user_id.present? && role.present? && ['normal', 'admin'].include?(role)
      render json: { success: false, error: '잘못된 요청입니다.' }, status: :bad_request
      return
    end

    user = User.find_by(id: user_id)
    
    unless user
      render json: { success: false, error: '사용자를 찾을 수 없습니다.' }, status: :not_found
      return
    end

    # 수퍼관리자는 변경할 수 없음
    if user.role == 'super_admin' || user.super_admin?
      render json: { success: false, error: '수퍼관리자의 역할은 변경할 수 없습니다.' }, status: :forbidden
      return
    end

    if user.update(role: role)
      render json: { success: true, message: '역할이 변경되었습니다.' }
    else
      render json: { success: false, error: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def check_super_admin
    unless current_user&.super_admin?
      redirect_to "/", alert: "수퍼관리자만 접근할 수 있습니다.", status: :forbidden
    end
  end
end
