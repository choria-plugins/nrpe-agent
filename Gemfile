# Managed by modulesync - DO NOT EDIT
# https://voxpupuli.org/docs/updating-files-managed-with-modulesync/

source "https://rubygems.org"

group :test do
  gem "mcollective-test", :require => false
  gem "mocha",            :require => false
  gem "rake",             :require => false
  gem "rspec",            :require => false
end

group :release do
  gem "voxpupuli-release", "~> 5.0", :require => false
end

mcollective_version = ENV["MCOLLECTIVE_GEM_VERSION"]

if mcollective_version
  gem "choria-mcorpc-support", mcollective_version, :require => false
else
  gem "choria-mcorpc-support", :require => false
end
