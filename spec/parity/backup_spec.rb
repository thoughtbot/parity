require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'parity')

describe Parity::Backup do
  it "restores backups to development (after dropping the development DB)" do
    allow(IO).to receive(:read).and_return(database_fixture)
    allow(Kernel).to receive(:system)
    allow(Etc).to receive(:nprocessors).and_return(number_of_processes)

    Parity::Backup.new(from: "production", to: "development").restore

    expect(Kernel).
      to have_received(:system).
      with(download_remote_database_command)
    expect(Kernel).
      to have_received(:system).
      with(drop_development_database_drop_command)
    expect(Kernel).
      to have_received(:system).
      with(restore_from_local_temp_backup_command)
    expect(Kernel).
      to have_received(:system).
      with(delete_local_temp_backup_command)
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

  def drop_development_database_drop_command(db_name: default_db_name)
    "dropdb #{db_name} && createdb #{db_name}"
  end

  def download_remote_database_command
    'curl -o tmp/latest.backup "$(heroku pg:backups:url --remote production)"'
  end

  def restore_from_local_temp_backup_command
    "pg_restore tmp/latest.backup --verbose --clean --no-acl --no-owner "\
      "--dbname #{default_db_name} --jobs #{number_of_processes} "
  end

  def number_of_processes
    2
  end

  def delete_local_temp_backup_command
    "rm tmp/latest.backup"
  end

  def heroku_development_to_staging_passthrough(db_name: default_db_name)
    "heroku pg:push #{db_name} DATABASE_URL --remote staging "
  end

  def heroku_production_to_staging_passthrough
    "heroku pg:backups:restore `heroku pg:backups:url "\
      "--remote production` DATABASE --remote staging "
  end

  def additional_argument_pass_through
    "heroku pg:backups:restore `heroku pg:backups:url "\
      "--remote production` DATABASE --remote staging "\
      "--confirm thisismyapp-staging"
  end

  def default_db_name
    "parity_development"
  end
end
