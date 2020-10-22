require 'rom/sql'

module Utils
  module Persistence
    class Relation < ROM::Relation[:sql]
      private

      def translated_column_from(relation, column)
        translated_name = translated_column_name_from(relation, column)

        relation[column].as(translated_name)
      end

      def translated_column_name_from(relation, column)
        tr_key = "column_translations.#{relation.name.to_sym}.#{column}"

        I18n.exists?(tr_key) ? I18n.t(tr_key).to_sym : column
      end

      def translated_columns_from(relation, columns)
        columns.map { translated_column_from(relation, _1) }
      end

      def translated_column_names_from(relation, columns)
        columns.map { translated_column_name_from(relation, _1) }
      end
    end
  end
end
