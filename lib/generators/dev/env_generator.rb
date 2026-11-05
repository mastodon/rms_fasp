module Dev
  class EnvGenerator < Rails::Generators::Base
    desc "Generate a new .env.development file"
    def generate_development_env_file
      create_file ".env.development", <<~VARIABLES
        GARAGE_DEFAULT_ACCESS_KEY="GK#{SecureRandom.hex(16)}"
        GARAGE_DEFAULT_SECRET_KEY="#{SecureRandom.hex(32)}"
        GARAGE_DEFAULT_BUCKET="rms"
        GARAGE_RPC_SECRET="#{SecureRandom.hex(32)}"
        AWS_REGION="garage"
        AWS_ENDPOINT_URL="http://localhost:3900"
        AWS_ACCESS_KEY_ID="${GARAGE_DEFAULT_ACCESS_KEY}"
        AWS_SECRET_ACCESS_KEY="${GARAGE_DEFAULT_SECRET_KEY}"
      VARIABLES
    end
  end
end
