source 'https://rubygems.org'
ruby '~> 3.0'

group :fastlane do
  gem 'fastlane'
  gem 'xcodeproj'
  gem 'xcode-install'
end

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
