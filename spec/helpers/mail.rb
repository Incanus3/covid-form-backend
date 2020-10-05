require 'mail'
require 'app/dependencies'

module Mail
  module Matchers
    class HasSentEmailMatcher
      alias old_matches_on_body_matcher? matches_on_body_matcher?

      def matches_on_body_matcher?(delivery)
        (old_matches_on_body_matcher?(delivery) ||
         delivery.body.parts.any? { |part| @body_matcher.match(part.decoded) })
      end
    end
  end
end

RSpec.configure do |config|
  config.include Mail::Matchers

  config.before(:suite) do
    CovidForm::Dependencies.start(:mail_sender)
  end

  config.before(:each) do
    Mail::TestMailer.deliveries.clear
  end
end
