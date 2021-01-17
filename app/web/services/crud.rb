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

        def relation
          repository.root
        end

        def schema
          relation.schema
        end

        def attribute_names
          schema.attributes.map(&:name)
        end

        def association_names
          schema.associations.elements.keys
        end

        def model
          repository.model
        end

        def all
          Success.new(entities: repository.all_by_id)
        end

        def all_with(assocs)
          Success.new(entities: repository.all_by_id_with(assocs.map(&:to_sym)))
        end

        def update(id, values)
          existing = repository.lock_by_id(id)

          if existing.exist?
            symbolized_values  = Utils::Hash.symbolize_keys(values)
            attribute_values   = symbolized_values.slice(*attribute_names)
            association_values = symbolized_values.slice(*association_names)

            updated = existing.command(:update).call(attribute_values)

            update_associations(id, association_values)

            Success.new(entity: updated)
          else
            NotFound.new(model, id)
          end
        end

        private

        def update_associations(id, association_values)
          association_values.each do |assoc_name, desired_related_ids|
            association   = schema.associations[assoc_name]
            join_relation = association.join_relation

            # :nocov:
            association.join_key_map in \
              [[source_id, join_source_fkey], [join_target_fkey, target_id]]
            # :nocov:

            currently_associated_ids = join_relation
              .where(join_source_fkey => id).pluck(join_target_fkey)

            ids_to_add    = desired_related_ids      - currently_associated_ids
            ids_to_remove = currently_associated_ids - desired_related_ids

            join_relation.where(join_source_fkey => id, join_target_fkey => ids_to_remove).delete

            join_relation.command(:create).call(ids_to_add.map { |related_id|
              { join_source_fkey => id, join_target_fkey => related_id }
            })
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
