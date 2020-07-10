require 'pry'

class AuthenticationController < ApplicationController
    skip_before_action :authenticate_request

    # def google
        # puts 'hello'
        # render json: { message: "hi" }
        # redirect_to '/auth/google_oauth2'
    # end
    
    def authenticate
        if request.env['omniauth.auth']
            render json: { auth_hash: 'yes' }
        end
        command = AuthenticateUser.call(user_params[:email], user_params[:password])
        # puts command.result[:token]
        # puts JsonWebToken.decode(command.result[:token])[:user_id][0]
        if command.success?
            render json: { auth_token: command.result[:token], user: command.result[:user] }
        else
            render json: { errors: command.errors[:user_authentication] }, status: :unauthorized
        end
    end

    def set_login
        # puts 'hello??'
        @current_user = AuthorizeApiRequest.call(request.headers).result
        if @current_user 
            render json: { user: @current_user }
        else 
            render json: { error: 'Not Authorized' }, status: 401
        end
    end

    def user_params
        params.permit(:email, :password)
    end
end
