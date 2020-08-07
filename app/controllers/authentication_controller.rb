require 'pry'

class AuthenticationController < ApplicationController
    skip_before_action :authenticate_request

    # puts JsonWebToken.decode(command.result[:token])[:user_id][0]

    def authenticate
        if user_params[:site]
            user = User.find_or_create_by_email(user_params[:email], user_params[:username])
            token = JsonWebToken.encode(user_id: user.id)
            render json: { auth_token: token, user: user }
        else
            command = AuthenticateUser.call(user_params[:email], user_params[:password])
            if command.success?
                render json: { auth_token: command.result[:token], user: command.result[:user] }
            else
                render json: { errors: command.errors[:user_authentication] }, status: :unauthorized
            end
        end 
    end

    def set_login
        @current_user = AuthorizeApiRequest.call(request.headers).result
        if @current_user 
            render json: { user: @current_user }
        else 
            render json: { error: 'Not Authorized' }, status: 401
        end
    end

    def user_params
        params.permit(:email, :password, :site, :username)
    end
end
