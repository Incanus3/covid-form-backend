require 'roda'

require 'app/dependencies'
require 'app/services/export'
require 'app/services/capacity'
require 'app/services/registration'

require_relative 'app_base'
require_relative 'validation'
require_relative 'serialization'
require_relative 'services/crud'

module CovidForm
  module Web
    class App < AppBase
      Dependencies.start(:persistence) # TODO: stop persistence on exit
      Dependencies.start(:mail_sender)

      # rubocop:disable Metrics/BlockLength
      route do |r|
        r.root do # GET /
          <<~HTML
            <h1>Seznam rout</h1>
            <ul>
              <li>POST /register</li>
              <li>GET /export</li>
              <li>GET /crud/time_slots</li>
              <li>GET /capacity/full_dates</li>
            </ul>
          HTML
        end

        r.is 'register' do
          r.post do # POST /register
            action(
              request,
              validation_contract: Validation::Contracts::Registration,
              result_serializer:   Serializers::RegistrationResult,
            ) do |params|
              Services::Registration.new(client_data: params[:client],
                                         exam_data:   params[:exam]).perform
            end
          end
        end

        r.on 'crud' do
          r.is 'exam_types' do
            r.get do # GET /crud/exam_types
              exam_types            = CRUD::ExamTypes.new.all
              response.status, body = Serializers::ExamType.serialize_many(exam_types)

              body
            end
          end
        end

        r.on 'capacity' do
          r.is 'full_dates' do
            r.get do # GET /capacity/full_dates
              action(
                request,
                validation_contract: Validation::Contracts::FullDates,
                result_serializer:   Serializers::FullDatesResult,
              ) do |params|
                Services::Capacity.new.full_dates_between(**params)
              end
            end
          end

          r.is 'available_time_slots' do
            r.get do # GET /crud/time_slots
              action(
                request,
                validation_contract: Validation::Contracts::TimeSlots,
                result_serializer:   Serializers::TimeSlot,
                multiple_results:    true,
              ) do |params|
                Services::Capacity.new
                  .available_time_slots_for(*params.values_at(:date, :exam_type))
              end
            end
          end
        end

        r.is 'export' do
          r.get do # GET /export
            authenticate!(request)

            action(
              request,
              validation_contract: Validation::Contracts::Export,
              result_serializer:   Serializers::ExportResult,
            ) do |params|
              Services::Export.new(params).perform
            end
          end
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end
