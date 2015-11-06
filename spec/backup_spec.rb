require File.join(File.dirname(__FILE__), '..', 'lib', 'parity')

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
    IO.read(database_fixture_path)
  end

  def database_fixture_path
    File.join(File.dirname(__FILE__), 'fixtures', 'database.yml')
  end

  def heroku_production_to_development_passthrough
    "heroku pg:pull DATABASE_URL parity_development --remote production "
  end

  def pg_restore
    "pg_restore --verbose --clean --no-acl --no-owner -d parity_development"
  end

  def drop_development_database_drop_command
    "dropdb parity_development"
  end

  def heroku_development_to_staging_passthrough
    "heroku pg:push parity_development DATABASE_URL --remote staging "
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
end
