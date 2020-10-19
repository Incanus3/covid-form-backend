require 'mail'

module CovidForm
  module Mailers
    class RegistrationConfirmation
      include Import[:mail_sender]

      attr_private_initialize %i[mail_sender client exam_type exam_date time_range]

      def send
        mail_sender.deliver(mail)
      end

      private

      def mail
        client    = self.client
        exam_info = { date: I18n.l(exam_date), time_range: time_range, exam_type: exam_type.upcase }

        Mail.new {
          to      client.email
          subject I18n.t('registration.success_email_subject')

          text_part do
            content_type 'text/plain; charset=UTF-8'
            body         I18n.t('registration.success_email_body', **exam_info)
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body         I18n.t('registration.success_email_html_body', **exam_info)
          end
        }
      end
    end
  end
end
