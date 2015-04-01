require "ember-cli/engine" if defined?(Rails)

module EmberCLI
  extend self

  autoload :App,           "ember-cli/app"
  autoload :Configuration, "ember-cli/configuration"
  autoload :Helpers,       "ember-cli/helpers"
  autoload :Middleware,    "ember-cli/middleware"

  def configure
    yield configuration
  end

  def configuration
    Configuration.instance
  end

  def get_app(name)
    configuration.apps[name]
  end

  def skip?
    ENV["SKIP_EMBER"]
  end

  def prepare!
    @prepared ||= begin
      Rails.configuration.assets.paths << assets_path.to_s
      at_exit{ cleanup }
      true
    end
  end

  def enable!
    prepare!

    if Helpers.use_middleware?
      Rails.configuration.middleware.use Middleware
    end
  end

  def install_dependencies!
    prepare!
    each_app &:install_dependencies
  end

  def run!
    prepare!
    each_app &:run
  end

  def run_tests!
    prepare!
    each_app &:run_tests
  end

  def compile!
    prepare!
    each_app &:compile
  end

  def stop!
    each_app &:stop
  end

  def wait!
    each_app &:wait
  end

  def root
    @root ||= Rails.root.join("tmp", "ember-cli-#{uid}")
  end

  def assets_path
    configuration.assets_path || root.join("assets").tap(&:mkpath)
  end

  private

  def uid
    @uid ||= SecureRandom.uuid
  end

  def cleanup
    return if (Rails.env == 'production' && Rails.version =~ /\A3\./) || ENV["EMBER_CLI_NO_CLEANUP"]
    each_app &:cleanup
    root.rmtree if root.exist?
  end

  def each_app
    configuration.apps.each{ |name, app| yield app }
  end
end
