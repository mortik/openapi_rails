# frozen_string_literal: true

module Api
  module V1
    class UsersController < ActionController::API
      include OpenapiRails::ControllerHelpers

      def index
        users = User.all
        render json: users.map { |u| user_json(u) }
      end

      def show
        user = User.find_by(id: params[:id])
        if user
          render json: user_json(user)
        else
          render json: {error: "Not found"}, status: :not_found
        end
      end

      def create
        user = User.new(user_params)
        if user.save
          render json: user_json(user), status: :created
        else
          render json: {errors: user.errors.full_messages}, status: :unprocessable_entity
        end
      end

      def update
        user = User.find_by(id: params[:id])
        return render(json: {error: "Not found"}, status: :not_found) unless user

        if user.update(user_params)
          render json: user_json(user)
        else
          render json: {errors: user.errors.full_messages}, status: :unprocessable_entity
        end
      end

      def destroy
        user = User.find_by(id: params[:id])
        return render(json: {error: "Not found"}, status: :not_found) unless user

        user.destroy
        head :no_content
      end

      private

      def user_params
        openapi_permit(Schemas::UserInput)
      end

      def user_json(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          createdAt: user.created_at&.iso8601,
          updatedAt: user.updated_at&.iso8601
        }
      end
    end
  end
end
