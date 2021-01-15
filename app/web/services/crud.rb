require 'dry/core/class_attributes'
require 'app/dependencies'

module CovidForm
  module Web
    module CRUD
      class CRUDService
        include Import[:db]
        extend Dry::Core::ClassAttributes

        defines :repo_name, type: Symbol
        repo_name :override_me

        attr_private_initialize [:db]

        def repository
          db.public_send(self.class.repo_name)
        end

        def all
          repository.all_by_id
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
