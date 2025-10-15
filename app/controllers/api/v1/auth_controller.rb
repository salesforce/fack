# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      # GET /api/v1/auth/validate
      # Validate current token and return user info
      def validate_token
        if current_user
          render json: {
            valid: true,
            user: {
              id: current_user.id,
              email: current_user.email
            },
            token_info: {
              last_used: current_user.api_tokens.where(active: true).maximum(:last_used),
              active_tokens: current_user.api_tokens.where(active: true).count
            }
          }
        else
          render json: {
            valid: false,
            error: 'Invalid or expired token'
          }, status: :unauthorized
        end
      end

      # POST /api/v1/auth/logout
      # Invalidate current token
      def logout
        if current_user
          # Find and deactivate the current token
          authenticate_with_http_token do |token, _options|
            current_api_token = ApiToken.where(active: true).find_by_token(token)
            if current_api_token
              current_api_token.update!(active: false)
              render json: {
                success: true,
                message: 'Token successfully invalidated'
              }
            else
              render json: {
                success: false,
                error: 'Token not found'
              }, status: :not_found
            end
          end
        else
          render json: {
            success: false,
            error: 'Not authenticated'
          }, status: :unauthorized
        end
      end
    end
  end
end
