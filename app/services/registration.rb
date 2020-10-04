require 'dry/monads'
require 'dry/monads/do'

require 'lib/transformations'
require 'app/dependencies'
require 'app/persistence/repository'

module CovidForm
  module Services
    class Registration
      include Import[:db, :repository, :mail_sender]
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:perform)

      class ClientAlreadyRegisteredForDate < Failure
        def initialize(client, date)
          super(I18n.t('registration.client_already_registered_for_date',
                       insurance_number: client.insurance_number, date: I18n.l(date)))
        end
      end

      attr_private_initialize [:db, :repository, :mail_sender, :data]

      def self.perform(data)
        new(data: data).perform
      end

      def perform
        db.transaction do
          client       = yield create_or_update_client
          registration = yield create_registration(client)

          yield send_mail(client)

          Success.new({ client: client, registration: registration })
        end
      end

      private

      def create_or_update_client
        client_data = self.data.slice(:first_name, :last_name, :municipality, :zip_code,
                                      :email, :phone_number, :insurance_number, :insurance_company)

        existing = repository.clients.lock_by_insurance_number(client_data[:insurance_number])

        client =
          if existing.empty?
            repository.clients.create(client_data)
          else
            without_ins_num = Utils::Hash.reject_keys(client_data, [:insurance_number])

            existing.update_returning(without_ins_num).first
          end

        Success.new(client)
      end

      def create_registration(client)
        registration_data = self.data
          .slice(:requestor_type, :exam_type, :exam_date)
          .merge({ client_id: client.id })

        begin
          Success.new(repository.registrations.create(registration_data))
        rescue Sequel::UniqueConstraintViolation # FIXME: this is an abstraciton leak
          ClientAlreadyRegisteredForDate.new(client, registration_data[:exam_date])
        end
      end

      # rubocop:disable Style/MethodCallWithArgsParentheses
      def send_mail(client)
        mail = mail_sender.deliver {
          to      client.email
          subject I18n.t('registration.success_email_subject')

          text_part do
            content_type 'text/plain; charset=UTF-8'
            body         I18n.t('registration.success_email_body')
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body         "<p>#{I18n.t('registration.success_email_body')}</p>"
          end
        }

        Success.new(mail)
      end
      # rubocop:enable Style/MethodCallWithArgsParentheses
    end
  end
end
