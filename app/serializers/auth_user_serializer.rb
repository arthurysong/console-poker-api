class AuthUserSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :chips
end