require 'rom/sql'

module Utils
  module Persistence
    class Relation < ROM::Relation[:sql]
      private

      def translated_column_from(relation, column)
        tr_key = "column_translations.#{relation.name.to_sym}.#{column}"

        relation[column].as(I18n.exists?(tr_key) ? I18n.t(tr_key).to_sym : column)
      end

      def translated_columns_from(relation, columns)
        columns.map { translated_column_from(relation, _1) }
      end
    end
  end
end
