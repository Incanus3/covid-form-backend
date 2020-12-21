module CovidForm
  module Persistence
    module Queries
      class RegistrationCapacity
        # @param db              [Sequel::Database]
        # @param time_slots      [ROM::SQL::Relation]
        # @param registrations   [ROM::SQL::Relation]
        # @param daily_overrides [ROM::SQL::Relation]
        attr_private_initialize %i[db registrations exam_types time_slots daily_overrides]

        # rubocop:disable Layout/MultilineBlockLayout, Layout/BlockEndNewline
        def dates_with_full_capacity(start_date, end_date, global_registration_limit:)
          registration_counts_by_date = registrations.counts_by_date.dataset.unordered

          date_sequence(start_date, end_date)
            .left_join(registration_counts_by_date, { exam_date: :date },
                       table_alias: :reg_counts)
            .left_join(daily_overrides.dataset, { date: Sequel.qualify(:date_seq, :date) },
                       table_alias: :reg_limits)
            .where { (coalesce(registration_count, 0) >=
                      coalesce(registration_limit, global_registration_limit)) }
            .select_map { Sequel.qualify(:date_seq, :date) }
        end
        # rubocop:enable Layout/MultilineBlockLayout, Layout/BlockEndNewline

        def daily_capacities_for(exam_type_id:, start_date:, end_date:, global_registration_limit:)
          reg_counts_and_limits_by_date_and_slot(exam_type_id, start_date, end_date,
                                                 global_registration_limit)
            .from_self
            .group_by(:date)
            .select {
              [
                date,
                sum(slot_limit).as(:maximum_capacity),
                Sequel.cast(greatest(sum(slot_limit) - sum(registration_count), 0), Integer)
                  .as(:available_slots),
              ]
            }
            .order(:date)
            .to_a
        end

        private

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def reg_counts_and_limits_by_date_and_slot(exam_type_id, start_date, end_date,
                                                   global_registration_limit)
          total_coef_sum      = time_slots.sum(:limit_coefficient)
          filtered_time_slots = time_slots.join(:exam_types).where(exam_types[:id] => exam_type_id)

          date_sequence(start_date, end_date)
            .left_join(daily_overrides.select(:date, :registration_limit).dataset.unordered,
                       { date: Sequel.qualify(:date_seq, :date) },
                       table_alias: :daily_overrides)
            .cross_join(filtered_time_slots.select(:id, :limit_coefficient).dataset.unordered,
                        table_alias: :time_slots)
            .left_join(registrations.counts_by_date_and_slot.dataset.unordered,
                       {
                         exam_date:    Sequel.qualify(:date_seq,   :date),
                         time_slot_id: Sequel.qualify(:time_slots, :id),
                       },
                       table_alias: :registration_counts)
            .select {
              [
                Sequel.qualify(:date_seq, :date),
                coalesce(Sequel.qualify(:registration_counts, :registration_count), 0)
                  .as(:registration_count),
                (coalesce(Sequel.qualify(:daily_overrides, :registration_limit),
                          global_registration_limit) *
                 Sequel.qualify(:time_slots, :limit_coefficient) / total_coef_sum).as(:slot_limit),
              ]
            }
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        def date_sequence(start_date, end_date)
          db
            .from   { generate_series(0, (end_date - start_date).to_i).as(:number) }
            .select { (Sequel.cast(start_date, Date) + number).as(:date)           }
            .from_self(alias: :date_seq)
        end
      end
    end
  end
end
