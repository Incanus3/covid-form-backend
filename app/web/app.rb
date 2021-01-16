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
    class App < AppBase # rubocop:disable Metrics/ClassLength
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
                request,
                validation_contract: Validation::Contracts::Export,
                result_serializer:   Serializers::ExportResult,
              ) do |params|
                Services::Export.new(params).perform
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
              r.is do
                r.get do # GET /admin/crud/time_slots
                  time_slots            = CRUD::TimeSlots.new.all
                  response.status, body = Serializers::TimeSlot.serialize_many(time_slots)

                  body
                end
              end

              r.is Integer do |id|
                r.put do # PUT /admin/crud/time_slots/:id
                  validation_result = Validation::Contracts::TimeSlot.new.call(request.params)

                  if validation_result.success?
                    service = CRUD::TimeSlots.new
                    result  = service.update(id, validation_result.to_h)

                    respond_with Serializers::CRUDServiceResult.serialize(service, result)
                  else
                    response.status, body =
                      Serializers::ValidationErrors.serialize(validation_result.errors)

                    body
                  end
                end
              end
            end
          end
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end
