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
    end
  end
end
