class AuthUserSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :username, :chips, :connected
end