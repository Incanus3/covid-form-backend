module CovidForm
  module Web
    module CRUD
      class ExamTypes
        include Import[:db]

        attr_private_initialize [:db]

        def all
          db.exam_types.all
        end
      end
    end
  end
end
