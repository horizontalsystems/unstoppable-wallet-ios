source 'https://rubygems.org'

group :fastlane do
  gem 'fastlane'
  gem 'cocoapods'
  gem 'xcodeproj'
end

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
