require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BackendNew
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Load YAML files
    config.categories = Psych.safe_load(File.read(Rails.root.join('config', 'data', 'categories.yaml')), aliases: true)
    config.fitnotes = Psych.safe_load(File.read(Rails.root.join('config', 'data', 'fitnotes.yaml')), aliases: true)
    config.modules = Psych.safe_load(File.read(Rails.root.join('config', 'data', 'modules.yaml')), aliases: true)
    config.skillplan = Psych.safe_load(File.read(Rails.root.join('config', 'data', 'skillplan.yaml')), aliases: true)
    config.skills = Psych.safe_load(File.read(Rails.root.join('config', 'data', 'skills.yaml')), aliases: true)

    config.middleware.use ActionDispatch::Cookies
    #config.middleware.use ActionDispatch::Session::CookieStore, key: '_backend_session'

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' # or your React app's host and port
        resource '*', headers: :any, methods: [:get, :post, :options]
      end
    end

    config.active_job.queue_adapter = :good_job

    config.good_job.cron = {
      fleet_updater: {
        class: 'FleetUpdaterJob',
        cron: 'every 30 seconds'
      }
    }

    config.good_job.enable_cron = true
  end
end
