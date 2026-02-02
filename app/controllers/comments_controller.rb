class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post
  before_action :set_comment, only: [:destroy]

  # POST /posts/:slug/comments
  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to post_path(@post), notice: "댓글이 작성되었습니다."
    else
      redirect_to post_path(@post), alert: "댓글 작성에 실패했습니다."
    end
  end

  # DELETE /posts/:slug/comments/:id
  def destroy
    @comment.destroy
    redirect_to post_path(@post), notice: "댓글이 삭제되었습니다."
  end

  private

  def set_post
    # slug로 포스트 찾기
    @post = Post.find_by!(slug: params[:slug] || params[:post_id])
  rescue ActiveRecord::RecordNotFound
    # 숫자인 경우 기존 ID로 인식하고 slug로 리다이렉트
    if (params[:slug] || params[:post_id]).match?(/^\d+$/)
      @post = Post.find(params[:slug] || params[:post_id])
      redirect_to post_path(@post), status: :moved_permanently
    else
      raise
    end
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
