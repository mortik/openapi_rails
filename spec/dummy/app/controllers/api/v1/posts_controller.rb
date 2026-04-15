# frozen_string_literal: true

module Api
  module V1
    class PostsController < ActionController::API
      include OpenapiRails::ControllerHelpers

      def index
        posts = if params[:user_id]
          Post.where(user_id: params[:user_id])
        else
          Post.all
        end
        render json: posts.map { |p| post_json(p) }
      end

      def show
        post = Post.find_by(id: params[:id])
        if post
          render json: post_json(post)
        else
          render json: {error: "Not found"}, status: :not_found
        end
      end

      def create
        post = Post.new(post_params)
        if post.save
          render json: post_json(post), status: :created
        else
          render json: {errors: post.errors.full_messages}, status: :unprocessable_entity
        end
      end

      def destroy
        post = Post.find_by(id: params[:id])
        return render(json: {error: "Not found"}, status: :not_found) unless post

        post.destroy
        head :no_content
      end

      private

      def post_params
        openapi_permit(Schemas::PostInput)
      end

      def post_json(post)
        {
          id: post.id,
          title: post.title,
          body: post.body,
          user_id: post.user_id,
          createdAt: post.created_at&.iso8601,
          updatedAt: post.updated_at&.iso8601
        }
      end
    end
  end
end
