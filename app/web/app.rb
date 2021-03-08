require 'roda'

require 'lib/web/responses'
require 'app/dependencies'
require 'app/services/export'
require 'app/services/capacity'
require 'app/services/configuration'
require 'app/services/registration'

require_relative 'app_base'
require_relative 'validation'
require_relative 'serialization'
require_relative 'services/crud'

module CovidForm
  module Web
    class App < AppBase # rubocop:disable Metrics/ClassLength
      Responses = Utils::Web::Responses

      Dependencies.start(:persistence) # TODO: stop persistence on exit
      Dependencies.start(:configuration)
      Dependencies.start(:mail_sender)

      enable_rodauth(Dependencies[:config][:auth])

      # :nocov:
      if Dependencies[:env] == :production
        error do |error|
          # TODO: when tested enough, return only some generic message in production env
          respond_with Serializers::Error.serialize(error)
        end
      end

      status_handler(404) do
        respond_with Responses::NotFound.with(error: 'resource not found')
      end

      status_handler(405) do
        respond_with Responses::MethodNotAllowed.with(error: 'method not allowed')
      end
      # :nocov:

      # rubocop:disable Metrics/BlockLength
      route do |r|
        r.root do # GET /
          <<~HTML
            <h1>Seznam rout</h1>
            <ul>
              <li>POST /registration/create</li>
              <li>GET /registration/allowed_dates</li>
              <li>GET /registration/full_dates</li>
              <li>GET /registration/available_time_slots</li>
              <li>GET /crud/exam_types</li>
            </ul>
          HTML
        end

        r.on 'auth' do
          r.rodauth
        end

        r.on 'registration' do
          r.is 'create', method: :post do # POST /registration/create
            action(
              validation_contract: Validation::Contracts::Registration,
              result_serializer:   Serializers::RegistrationResult,
            ) do |params|
              Services::Registration.new(
                client_data: params[:client], exam_data: params[:exam],
              ).perform
            end
          end

          r.is 'allowed_dates', method: :get do # GET /registration/allowed_dates
            respond_with Responses::OK.with(Services::Configuration.new.allowed_exam_dates)
          end

          r.is 'full_dates', method: :get do # GET /registration/full_dates
            action(
              validation_contract: Validation::Contracts::FullDates,
              result_serializer:   Serializers::FullDatesResult,
            ) do |params|
              Services::Capacity.new.full_dates_between(**params)
            end
          end

          r.is 'available_time_slots', method: :get do # GET /registration/available_time_slots
            action(
              validation_contract: Validation::Contracts::AvailableTimeSlots,
              result_serializer:   Serializers::TimeSlot,
              multiple_results:    true,
              serializer_options:  { with_coefficient: false },
            ) do |params|
              Services::Capacity.new.available_time_slots_for(*params.values_at(:date, :exam_type))
            end
          end
        end

        r.on 'crud' do
          r.is 'exam_types' do
            get_all_action(service: CRUD::ExamTypes)
          end
        end

        r.on 'admin' do
          rodauth.require_authentication

          r.is 'export', method: :get do # GET /export
            action(
              validation_contract: Validation::Contracts::Export,
              result_serializer:   Serializers::ExportResult,
            ) do |params|
              Services::Export.new(**params).perform
            end
          end

          r.on 'crud' do
            r.on 'exam_types' do
              # GET    /admin/crud/exam_types
              # POST   /admin/crud/exam_types
              # PUT    /admin/crud/exam_types/:id
              # DELETE /admin/crud/exam_types/:id
              crud_actions(
                service:             CRUD::ExamTypes,
                validation_contract: Validation::Contracts::ExamType,
              )
            end

            r.on 'time_slots' do
              # GET    /admin/crud/time_slots
              # POST   /admin/crud/time_slots
              # PUT    /admin/crud/time_slots/:id
              # DELETE /admin/crud/time_slots/:id
              crud_actions(
                service:             CRUD::TimeSlots,
                validation_contract: Validation::Contracts::TimeSlot,
              )
            end

            r.on 'daily_overrides' do
              # TODO: return only for future dates

              # GET    /admin/crud/daily_overrides
              # POST   /admin/crud/daily_overrides
              # PUT    /admin/crud/daily_overrides/:id
              # DELETE /admin/crud/daily_overrides/:id
              crud_actions(
                service:             CRUD::DailyOverrides,
                validation_contract: Validation::Contracts::DailyOverride,
              )
            end

            r.on 'settings' do
              service             = CRUD::Settings
              validation_contract = Validation::Contracts::Setting

              request.is do
                r.get do # GET /admin/crud/settings
                  settings = Dependencies[:config].to_a.reject { |setting| setting[:key] == :auth }

                  { settings: settings }
                end

                # POST /admin/crud/settings
                create_action(service: service, validation_contract: validation_contract)
              end

              request.is String do |id|
                # PUT    /admin/crud/settings/:id
                update_action(id, service: service, validation_contract: validation_contract)

                # DELETE /admin/crud/settings/:id
                delete_action(id, service: service)
              end
            end
          end
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end
