require 'lib/utils'
require 'lib/persistence/container'

require 'app/entities'

require_relative 'repositories'

module CovidForm
  module Persistence
    class Container < Utils::Persistence::Container
      DEFAULT_CONFIG_OPTIONS = {
        migrator:          {
          path: File.join(APP_ROOT, 'app', 'persistence', 'migrations'),
        },
        auto_registration: {
          root_dir:  File.join(APP_ROOT, 'app', 'persistence'),
          namespace: 'CovidForm::Persistence',
        },
      }.freeze

      DEFAULT_REPO_OPTIONS = {
        auto_struct:      true,
        struct_namespace: CovidForm::Entities,
      }.freeze

      register_repo(Persistence::Repositories::Clients)
      register_repo(Persistence::Repositories::Settings)
      register_repo(Persistence::Repositories::ExamTypes)
      register_repo(Persistence::Repositories::TimeSlots)
      register_repo(Persistence::Repositories::TimeSlotExamTypes)
      register_repo(Persistence::Repositories::Registrations)
      register_repo(Persistence::Repositories::DailyOverrides)
    end
  end
end
