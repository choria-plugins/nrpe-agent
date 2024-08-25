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

desc "Expands the action details section in a README.md file"
task :readme_expand do
  ddl_file = Dir.glob("agent/*.ddl").first

  return unless ddl_file

  ddl = MCollective::DDL.new("package", :agent, false)
  ddl.instance_eval(File.read(ddl_file))

  lines = File.readlines("puppet/README.md").map do |line|
    if line.match?(/^<!--- actions -->/)
      [
        "## Actions\n\n",
        "This agent provides the following actions, for details about each please run `mco plugin doc agent/%s`\n\n" % ddl.meta[:name]
      ] + ddl.entities.keys.sort.map do |action|
        " * **%s** - %s\n" % [action, ddl.entities[action][:description]]
      end
    else
      line
    end
  end.flatten

  File.open("puppet/README.md", "w") do |f|
    f.print lines.join
  end
end

desc "Set versions for a release"
task :prep_version do
  abort("Please specify VERSION") unless ENV["VERSION"]

  Rake::FileList["**/*.ddl"].each do |file|
    sh 'sed -i"" -re \'s/(\s+:version\s+=>\s+").+/\1%s",/\' %s' % [ENV["VERSION"], file]
  end
end

desc "Prepares for a release"
task :build_prep do
  if ENV["VERSION"]
    Rake::Task[:test].execute
    Rake::Task[:prep_version].execute
  end

  mkdir_p "puppet"

  cp "README.md", "puppet"
  cp "CHANGELOG.md", "puppet"
  cp "LICENSE", "puppet"
  cp "NOTICE", "puppet"

  Rake::Task[:readme_expand].execute
end

desc "Builds the module found in the current directory, run build_prep first"
task :build do
  sh "/opt/puppetlabs/puppet/bin/mco plugin package --format aiomodulepackage --vendor choria"
end

# load optional tasks for releases
# only available if gem group releases is installed
begin
  require "voxpupuli/release/rake_tasks"
rescue LoadError
  # voxpupuli-release not present
end
