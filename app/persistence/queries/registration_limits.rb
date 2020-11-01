module CovidForm
  module Persistence
    module Queries
      class RegistrationCapacity
        attr_private :db, :daily_overrides, :registration_counts_by_dates

        # @param db              [Sequel::Database]
        # @param registrations   [ROM::SQL::Relation]
        # @param daily_overrides [ROM::SQL::Relation]
        def initialize(db:, registrations:, daily_overrides:)
          @db                           = db
          @daily_overrides              = daily_overrides.dataset
          @registration_counts_by_dates = registrations.counts_by_dates.dataset
        end

        # rubocop:disable Layout/MultilineBlockLayout, Layout/BlockEndNewline
        def dates_with_full_capacity(start_date, end_date, global_registration_limit:)
          date_sequence(start_date, end_date)
            .left_join(registration_counts_by_dates, { exam_date: :date },
                       table_alias: :reg_counts)
            .left_join(daily_overrides, { date: Sequel.qualify(:date_seq, :date) },
                       table_alias: :reg_limits)
            .where { (coalesce(registration_count, 0) >=
                      coalesce(registration_limit, global_registration_limit)) }
            .select_map { Sequel.qualify(:date_seq, :date) }
        end
        # rubocop:enable Layout/MultilineBlockLayout, Layout/BlockEndNewline

        private

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
