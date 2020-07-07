class JsonWebToken
    class << self
        def encode(payload)
        # def encode(payload, exp = 24.hours.from_now)
            # payload[:exp] = exp.to_i
            puts Rails.application.secrets.secret_key_base
            JWT.encode(payload, Rails.application.secrets.secret_key_base)
        end

        def decode(token)
            # JWT.decode(request['token'], Rails.application.secrets.secret_key_base)
            body = JWT.decode(token, Rails.application.secrets.secret_key_base)
            HashWithIndifferentAccess.new body 
        rescue
            nil
        end
    end
end
