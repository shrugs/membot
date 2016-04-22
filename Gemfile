source 'https://rubygems.org'


gem 'rails', '>= 5.0.0.beta3', '< 5.1'

gem 'pg'
gem 'aasm'
gem 'puma'
gem 'httparty'
gem 'nested-hstore'

group :development do
  gem 'listen'
  gem 'spring'
end

group :development, :test do
  gem 'dotenv-rails'

  gem 'pry-rails'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'
  gem 'pry-rescue'
  gem 'pry-doc'

  gem 'thin'
end

group :staging, :production do
  gem 'rails_12factor'
end