class AuthUserSerializer
    include FastJsonapi::ObjectSerializer
    # attributes :id, :username, :chips, :connected, :game_id
    attributes :id, :username, :chips, :connected, :game_id
end