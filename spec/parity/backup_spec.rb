require "climate_control"

require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'parity')

describe Parity::Backup do
  it "restores backups to development (after dropping the development DB)" do
    allow(IO).to receive(:read).and_return(database_fixture)
    allow(Kernel).to receive(:system)

    Parity::Backup.new(from: "production", to: "development").restore

    expect(Kernel).
      to have_received(:system).
      with(drop_development_database_drop_command)
    expect(Kernel).
      to have_received(:system).
      with(heroku_production_to_development_passthrough)
  end

  context "with a database.yml that uses ERB and environment variables" do
    around do |example|
      ClimateControl.modify DEVELOPMENT_DATABASE_NAME: "erb_database_name" do
        example.run
      end
    end

    it "correctly parses database.yml" do
      development_db = ENV["DEVELOPMENT_DATABASE_NAME"]
      allow(IO).to receive(:read).and_return(database_with_erb_fixture)
      allow(Kernel).to receive(:system)

      Parity::Backup.new(from: "production", to: "development").restore

      expect(Kernel).
        to have_received(:system).
        with(
          drop_development_database_drop_command(db_name: development_db),
        )
      expect(Kernel).
        to have_received(:system).
        with(
          heroku_production_to_development_passthrough(
            db_name: development_db,
          ),
        )
    end
  end

  it "restores backups to staging from production" do
    allow(Kernel).to receive(:system)

    Parity::Backup.new(from: "production", to: "staging").restore

    expect(Kernel).
      to have_received(:system).
      with(heroku_production_to_staging_passthrough)
  end

  it "restores backups to staging from development" do
    allow(IO).to receive(:read).and_return(database_fixture)
    allow(Kernel).to receive(:system)

    Parity::Backup.new(from: "development", to: "staging").restore

    expect(Kernel).
      to have_received(:system).
      with(heroku_development_to_staging_passthrough)
  end

  it "passes additional arguments to the subcommand" do
    allow(Kernel).to receive(:system)

    Parity::Backup.new(
      from: "production",
      to: "staging",
      additional_args: "--confirm thisismyapp-staging",
    ).restore

    expect(Kernel).
      to have_received(:system).with(additional_argument_pass_through)
  end

  def database_fixture
    IO.read(fixture_path("database.yml"))
  end

  def database_with_erb_fixture
    IO.read(fixture_path("database_with_erb.yml"))
  end

  def fixture_path(filename)
    File.join(File.dirname(__FILE__), "..", "fixtures", filename)
  end

  def heroku_production_to_development_passthrough(db_name: default_db_name)
    "heroku pg:pull DATABASE_URL #{db_name} --remote production "
  end

  def drop_development_database_drop_command(db_name: default_db_name)
    "dropdb #{db_name}"
  end

  def heroku_development_to_staging_passthrough(db_name: default_db_name)
    "heroku pg:push #{db_name} DATABASE_URL --remote staging "
  end

  def heroku_production_to_staging_passthrough
    "heroku pg:backups restore `heroku pg:backups public-url "\
      "--remote production` DATABASE --remote staging "
  end

  def additional_argument_pass_through
    "heroku pg:backups restore `heroku pg:backups public-url "\
      "--remote production` DATABASE --remote staging "\
      "--confirm thisismyapp-staging"
  end

  def default_db_name
    "parity_development"
  end
end
