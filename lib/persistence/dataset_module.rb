module Utils
  module Persistence
    module DatasetModule
      def update_returning(...)
        returning.update(...).map(&row_proc)
      end
    end
  end
end
