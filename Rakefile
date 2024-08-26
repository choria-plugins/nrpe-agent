# Managed by modulesync - DO NOT EDIT
# https://voxpupuli.org/docs/updating-files-managed-with-modulesync/

specdir = File.join([File.dirname(__FILE__), "spec"])

require "rake"
begin
  require "rspec/core/rake_task"
  require "mcollective"
rescue LoadError # rubocop:disable Lint/SuppressedException
end


desc "Run agent and application tests"
task :test do
  require "#{specdir}/spec_helper.rb"
  if ENV["TARGETDIR"]
    test_pattern = "#{File.expand_path(ENV['TARGETDIR'])}/spec/**/*_spec.rb"
  else
    test_pattern = "spec/**/*_spec.rb"
  end
  sh "bundle exec rspec #{Dir.glob(test_pattern).sort.join(' ')}"
end

task :default => [:test]

desc "Set versions for a release"
task :prep_version do
  abort("Please specify VERSION") unless ENV["VERSION"]

  Rake::FileList["**/*.ddl"].each do |file|
    sh 'sed -i "" -re \'s/([\t ]+:version[\t ]+=>[\t ]+").+/\\1%s",/\' %s' % [ENV["VERSION"], file]
  end

  Rake::FileList["**/*.json"].each do |file|
    sh 'sed -i "" -re \'s/("version": ").+/\\1%s",/\' %s' % [ENV["VERSION"], file]
  end

  changelog = File.read("CHANGELOG.md")
  File.open("CHANGELOG.md", "w") do |f|
    done = false
    changelog.lines.each do |line|
      if line =~ /^## / && !done
        done = true
        puts "Adding a new entry to CHANGELOG.md:"
        puts "-------------------- 8< --------------------"
        new_entry = <<~END_CHANGELOG
          ## #{ENV['VERSION']}

          Released #{Time.now.strftime('%Y-%m-%d')}

          #{`git log --oneline $(git tag | tail -n 1)..HEAD`.lines.map { |l| l.sub(/^/, ' * ')}.join}
        END_CHANGELOG
        puts new_entry
        puts "-------------------- 8< --------------------"
        f.puts new_entry
      end
      f.puts line
    end
  end
end

# load optional tasks for releases
# only available if gem group releases is installed
begin
  require "voxpupuli/release/rake_tasks"
rescue LoadError
  # voxpupuli-release not present
end
