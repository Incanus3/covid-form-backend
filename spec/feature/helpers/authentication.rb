module CovidForm
  module TestHelpers
    module Authentication
      ADMIN_EMAIL    = 'admin@test.cz'.freeze
      ADMIN_PASSWORD = 'password'.freeze

      def populate_account_statuses
        db.sequel_db
          .from(:account_statuses)
          .import([:id, :name], [[1, 'Unverified'], [2, 'Verified'], [3, 'Closed']])
      end

      def create_admin_account(email = ADMIN_EMAIL, password = ADMIN_PASSWORD)
        sequel_db = db.sequel_db

        account_id = sequel_db[:accounts].insert(
          email:     email,
          status_id: 2, # verified
        )

        sequel_db[:account_password_hashes].insert(
          id:            account_id,
          password_hash: BCrypt::Password.create(password).to_s,
        )
      end

      def log_in(email, password)
        post_json '/auth/login', { login: email, password: password }

        token = last_response.json['access_token']

        header 'Authorization', token
      end

      def log_in_admin
        log_in(ADMIN_EMAIL, ADMIN_PASSWORD)
      end
    end
  end
end
