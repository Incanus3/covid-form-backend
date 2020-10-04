guard :bundler do
  require 'guard/bundler'
  require 'guard/bundler/verify'

  helper = Guard::Bundler::Verify.new

  files = ['Gemfile']
  files += Dir['*.gemspec'] if files.any? { |f| helper.uses_gemspec?(f) }

  # Assume files are symlinked from somewhere
  files.each { |file| watch(helper.real_path(file)) }
end

group :red_green_refactor, halt_on_fail: true do # rubocop:disable Metrics/BlockLength
  guard :rspec, cmd: 'bundle exec rspec -f d --order rand' do
    require 'guard/rspec/dsl'

    dsl = Guard::RSpec::Dsl.new(self)

    app_files  = %r{^app/(.+)\.rb$}
    main_files = /app.rb|config.ru/

    watch(main_files)         { dsl.rspec.spec_dir }
    watch(app_files)          { dsl.rspec.spec_dir }
    watch(dsl.ruby.lib_files) { dsl.rspec.spec_dir }

    watch(dsl.rspec.spec_files)
    watch(dsl.rspec.spec_helper)  { dsl.rspec.spec_dir }
    watch(dsl.rspec.spec_support) { dsl.rspec.spec_dir }
  end

  guard :rubocop, cli: ['-D'] do
    watch('Rakefile')
    watch(/.+\.rb$/)
    watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
  end
end
