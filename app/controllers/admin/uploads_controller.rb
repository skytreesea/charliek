class Admin::UploadsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin
  before_action :check_super_admin_for_destroy, only: [:destroy]

  def index
    @uploads = ActiveStorage::Blob.order(created_at: :desc).limit(20)
  end

  def create
    if params[:file].present?
      file = params[:file]
      processed_file = nil
      
      begin
        # 이미지 파일인 경우에만 압축 처리
        if file.content_type&.start_with?('image/')
          begin
            processed_file = process_image(file)
            
            # 처리된 파일이 원본과 다른지 확인 (WebP 변환 성공 여부)
            if processed_file && processed_file != file
              io = processed_file
              filename = file.original_filename.to_s.gsub(/\.[^.]+$/, '.webp')
              content_type = 'image/webp'
            else
              # 처리 실패 시 원본 파일 사용
              io = file
              filename = file.original_filename
              content_type = file.content_type
            end
          rescue => e
            Rails.logger.error "Image processing exception: #{e.class} - #{e.message}"
            Rails.logger.error e.backtrace.first(10).join("\n")
            # 압축 실패 시 원본 파일 사용
            io = file
            filename = file.original_filename
            content_type = file.content_type
            processed_file = nil
          end
        else
          io = file
          filename = file.original_filename
          content_type = file.content_type
        end
        
        blob = ActiveStorage::Blob.create_and_upload!(
          io: io,
          filename: filename,
          content_type: content_type
        )
        
        image_url = request.base_url + Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
        
        original_size = file.size rescue 0
        compressed_size = blob.byte_size
        
        render json: {
          success: true,
          url: image_url,
          filename: blob.filename.to_s,
          size: blob.byte_size,
          original_size: original_size,
          compressed: original_size > 0 && compressed_size < original_size,
          content_type: blob.content_type
        }
      ensure
        # 임시 파일 정리
        if processed_file && processed_file.respond_to?(:close!)
          processed_file.close!
        elsif processed_file && processed_file.respond_to?(:unlink)
          processed_file.unlink rescue nil
        end
      end
    else
      render json: { success: false, error: "파일이 없습니다." }, status: :bad_request
    end
  rescue => e
    Rails.logger.error "Upload error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def destroy
    blob = ActiveStorage::Blob.find_by(id: params[:id])
    
    if blob.nil?
      redirect_to admin_uploads_path, alert: "이미지를 찾을 수 없습니다.", status: :not_found
      return
    end

    begin
      # 연결된 attachments도 함께 삭제
      blob.attachments.each(&:purge)
      blob.purge
      
      redirect_to admin_uploads_path, notice: "이미지가 삭제되었습니다."
    rescue => e
      Rails.logger.error "Delete error: #{e.message}"
      redirect_to admin_uploads_path, alert: "이미지 삭제 중 오류가 발생했습니다: #{e.message}"
    end
  end

  private

  def check_admin
    unless current_user&.admin?
      redirect_to "/", alert: "관리자만 접근할 수 있습니다.", status: :forbidden
    end
  end

  def check_super_admin_for_destroy
    unless current_user&.super_admin?
      redirect_to admin_uploads_path, alert: "수퍼관리자만 이미지를 삭제할 수 있습니다.", status: :forbidden
    end
  end

  def process_image(file)
    # 파일을 다시 읽을 수 있도록 준비
    file.rewind if file.respond_to?(:rewind)
    
    # 뉴스 사이트용 공격적 최적화: 품질 50, 최대 800px, WebP 변환
    begin
      require 'image_processing/vips'
      return ImageProcessing::Vips
        .source(file)
        .resize_to_limit(800, nil)  # 가로 800px 제한, 세로는 비율 유지
        .saver(format: :webp, quality: 50, strip: true)  # WebP 포맷으로 강제 변환, 품질 50
        .call
    rescue LoadError, NameError => e
      Rails.logger.debug "Vips not available: #{e.message}, trying MiniMagick"
    rescue => e
      Rails.logger.error "Vips processing error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
    end
    
    # MiniMagick 사용 시도
    begin
      require 'image_processing/mini_magick'
      file.rewind if file.respond_to?(:rewind)
      return ImageProcessing::MiniMagick
        .source(file)
        .resize_to_limit(800, nil)  # 가로 800px 제한, 세로는 비율 유지
        .saver(format: :webp, quality: 50, strip: true)  # WebP 포맷으로 강제 변환, 품질 50
        .call
    rescue LoadError, NameError => e
      Rails.logger.warn "MiniMagick not available: #{e.message}"
    rescue => e
      Rails.logger.error "MiniMagick processing error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
    end
    
    # 둘 다 없으면 원본 파일 반환
    Rails.logger.warn "Image processing failed, returning original file"
    file.rewind if file.respond_to?(:rewind)
    file
  end
end
