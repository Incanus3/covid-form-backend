require 'base_helper'
require 'lib/mail_sender'
require 'spec/helpers/mail'

# rubocop:disable RSpec/VariableDefinition, RSpec/VariableName
RSpec.describe Utils::MailSender do
  subject(:mail_sender) { described_class.new(env: :test, default_from: 'default@test.cz') }

  it 'can send email constructed in block' do
    mail_sender.deliver do
      to      'to@test.cz'
      subject 'test subject'
      body    'test body'
    end

    is_expected.to have_sent_email
      .to('to@test.cz')
      .with_subject('test subject')
      .with_body('test body')
  end

  it 'can send email passed as argument' do
    mail = Mail.new {
      to      'to@test.cz'
      subject 'test subject'
      body    'test body'
    }

    mail_sender.deliver(mail)

    is_expected.to have_sent_email
      .to('to@test.cz')
      .with_subject('test subject')
      .with_body('test body')
  end

  it 'provides default from if not given' do
    mail_sender.deliver do
      to      'to@test.cz'
      subject 'test subject'
      body    'test body'
    end

    is_expected.to have_sent_email.from('default@test.cz')
  end

  it 'does not override from if given' do
    mail_sender.deliver do
      from    'from@test.cz'
      to      'to@test.cz'
      subject 'test subject'
      body    'test body'
    end

    is_expected.to have_sent_email.from('from@test.cz')
  end

  it 'handles case when neither mail nor block is given' do
    expect {
      mail_sender.deliver
    }.to raise_exception(/either.*message.*or a block/i)
  end

  it 'handles case when both mail and block are given' do
    expect {
      mail_sender.deliver(:mail) {} # dummy block
    }.to raise_exception(/either.*message.*or a block/i)
  end
end
# rubocop:enable RSpec/VariableDefinition, RSpec/VariableName
