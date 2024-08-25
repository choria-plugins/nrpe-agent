#!ruby
source 'https://rubygems.org'

group :test do
  gem 'rake', '>= 12.3.3'
  gem 'rspec'
  gem 'mocha'
  gem 'mcollective-test'
end

mcollective_version = ENV['MCOLLECTIVE_GEM_VERSION']

if mcollective_version
  gem 'mcollective-client', mcollective_version, :require => false
else
  gem 'mcollective-client', :require => false
end
