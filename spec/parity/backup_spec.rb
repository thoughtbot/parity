require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'parity')

describe Parity::Backup do
  it "restores backups to development (after dropping the development DB)" do
    allow(IO).to receive(:read).and_return(database_fixture)
    allow(Kernel).to receive(:system)

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

  it "restores backups to dockerized development (after dropping the development DB)" do
    allow(IO).to receive(:read).and_return(database_fixture)
    allow(File).to receive(:exists?).and_return(docker_compose_fixture)
    allow(Kernel).to receive(:system)

    Parity::Backup.new(from: "production", to: "development").restore

    expect(Kernel).
      to have_received(:system).
      with(download_remote_database_command)
    expect(Kernel).
      to have_received(:system).
      with(drop_dockerized_development_database_drop_command)
    expect(Kernel).
      to have_received(:system).
      with(create_dockerized_development_database_create_command)
    expect(Kernel).
      to have_received(:system).
      with(dockerized_restore_from_local_temp_backup_command)
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

  def docker_compose_fixture
    File.exists?(fixture_path("docker-compose.yml"))
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

  def drop_dockerized_development_database_drop_command(db_name: default_db_name)
    "docker-compose exec db dropdb -U postgres #{db_name}"
  end

  def create_dockerized_development_database_create_command(db_name: default_db_name)
    "docker-compose exec db createdb -U postgres #{db_name}"
  end

  def download_remote_database_command
    'curl -o tmp/latest.backup "$(production pg:backups public-url -q)"'
  end

  def dockerized_restore_from_local_temp_backup_command
    "docker-compose exec db "\
     "pg_restore -U postgres tmp/latest.backup --verbose --clean --no-acl --no-owner "\
      "-d #{default_db_name} "
  end

  def restore_from_local_temp_backup_command
    "pg_restore tmp/latest.backup --verbose --clean --no-acl --no-owner "\
      "-d #{default_db_name} "
  end

  def delete_local_temp_backup_command
    "rm tmp/latest.backup"
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
