module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def find_verified_user 
      puts 'wtf?'
      # if current_user = User.find(JWT.decode(params['token'], Rails.application.secrets.secret_key_base)[0]["user_id"])
      if current_user = User.find(JWT.decode(params['token'], ENV['SECRET_KEY_BASE'])[0]["user_id"])
        current_user
      else
        reject
      end
    end
  end
end
