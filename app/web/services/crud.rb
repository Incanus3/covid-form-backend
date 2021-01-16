require 'dry/core/class_attributes'
require 'dry/monads'
require 'lib/utils'
require 'app/dependencies'

module CovidForm
  module Web
    module CRUD
      class CRUDService
        include Import[:db]
        include Dry::Monads[:result]
        extend  Dry::Core::ClassAttributes

        class NotFound < Failure
          def initialize(model, id)
            super({ model: model, id: id })
          end
        end

        defines :repo_name, type: Symbol
        repo_name :override_me

        attr_private_initialize [:db]

        def repository
          db.public_send(self.class.repo_name)
        end

        def model
          repository.model
        end

        def all
          repository.all_by_id
        end

        def update(id, attributes)
          existing = repository.lock_by_id(id)

          if existing.exist?
            updated = existing.command(:update).call(Utils::Hash.symbolize_keys(attributes))

            Success.new(updated)
          else
            NotFound.new(model, id)
          end
        end
      end

      class ExamTypes < CRUDService
        repo_name :exam_types
      end

      class TimeSlots < CRUDService
        repo_name :time_slots
      end
    end
  end
end
