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

      enable_rodauth(Dependencies[:config][:auth])

      # TODO: add error handler so that 500 requests don't fail CORS checks
      # TODO: convert all serializer results to Response instances,
      # then we can use respond_with everywhere

      status_handler(404) do
        { error: 'resource not found' }
      end

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

        r.on 'auth' do
          r.rodauth
        end

        r.is 'register' do
          r.post do # POST /register
            action(
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
              service = CRUD::ExamTypes.new

              respond_with Serializers::CRUDServiceResult.serialize(service, service.all)
            end
          end
        end

        r.on 'capacity' do
          r.is 'full_dates' do
            r.get do # GET /capacity/full_dates
              action(
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
                validation_contract: Validation::Contracts::AvailableTimeSlots,
                result_serializer:   Serializers::TimeSlot,
                multiple_results:    true,
                serializer_options:  { with_coefficient: false },
              ) do |params|
                Services::Capacity.new
                  .available_time_slots_for(*params.values_at(:date, :exam_type))
              end
            end
          end
        end

        r.on 'admin' do
          rodauth.require_authentication

          r.is 'export' do
            r.get do # GET /export
              action(
                validation_contract: Validation::Contracts::Export,
                result_serializer:   Serializers::ExportResult,
              ) do |params|
                Services::Export.new(**params).perform
              end
            end
          end

          r.is 'settings' do
            r.get do # GET /admin/settings
              {
                settings: {
                  daily_registration_limit: Dependencies[:config][:daily_registration_limit],
                },
              }
            end
          end

          r.on 'crud' do
            r.on 'time_slots' do
              # GET /admin/crud/time_slots
              # PUT /admin/crud/time_slots/:id
              crud_actions(
                service:             CRUD::TimeSlots,
                validation_contract: Validation::Contracts::TimeSlot,
              )
            end
          end
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end
