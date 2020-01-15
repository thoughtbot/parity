require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'parity')

describe Parity::Backup do
  context "restoring to the local development environment" do
    it "restores backups to development (after dropping the development DB)" do
      allow(IO).to receive(:read).and_return(database_fixture)
      allow(Kernel).to receive(:system)
      allow(Etc).to receive(:nprocessors).and_return(number_of_processes)

      Parity::Backup.new(
        from: "production",
        to: "development",
        parallelize: true,
      ).restore

      expect(Kernel).
        to have_received(:system).
        with(make_temp_directory_command)
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

    it "restores backups to development with Rubies that do not support Etc.nprocessors" do
      allow(IO).to receive(:read).and_return(database_fixture)
      allow(Kernel).to receive(:system)
      allow(Etc).to receive(:respond_to?).with(:nprocessors).and_return(false)

      Parity::Backup.new(
        from: "production",
        to: "development",
        parallelize: false,
      ).restore

      expect(Kernel).
        to have_received(:system).
        with(make_temp_directory_command)
      expect(Kernel).
        to have_received(:system).
        with(download_remote_database_command)
      expect(Kernel).
        to have_received(:system).
        with(drop_development_database_drop_command)
      expect(Kernel).
        to have_received(:system).
        with(restore_from_local_temp_backup_command(cores: 1))
      expect(Kernel).
        to have_received(:system).
        with(delete_local_temp_backup_command)
    end

    it "restores backups in parallel when the right flag is set" do
      allow(IO).to receive(:read).and_return(database_fixture)
      allow(Kernel).to receive(:system)
      allow(Etc).to receive(:nprocessors).and_return(12)

      Parity::Backup.new(
        from: "production",
        to: "development",
        parallelize: true,
      ).restore

      expect(Kernel).
        to have_received(:system).
        with(make_temp_directory_command)
      expect(Kernel).
        to have_received(:system).
        with(download_remote_database_command)
      expect(Kernel).
        to have_received(:system).
        with(drop_development_database_drop_command)
      expect(Kernel).
        to have_received(:system).
        with(restore_from_local_temp_backup_command(cores: 12))
      expect(Kernel).
        to have_received(:system).
        with(delete_local_temp_backup_command)
    end

    it "does not restore backups in parallel when the right flag is set" +
      "but the ruby version is under 2.2" do
      allow(IO).to receive(:read).and_return(database_fixture)
      allow(Kernel).to receive(:system)
      allow(Etc).to receive(:respond_to?).with(:nprocessors).and_return(false)

      Parity::Backup.new(
        from: "production",
        to: "development",
        parallelize: true,
      ).restore

      expect(Kernel).
        to have_received(:system).
        with(make_temp_directory_command)
      expect(Kernel).
        to have_received(:system).
        with(download_remote_database_command)
      expect(Kernel).
        to have_received(:system).
        with(drop_development_database_drop_command)
      expect(Kernel).
        to have_received(:system).
        with(restore_from_local_temp_backup_command(cores: 1))
      expect(Kernel).
        to have_received(:system).
        with(delete_local_temp_backup_command)
    end

    it "drops the 'ar_internal_metadata' table if it exists" do
      allow(IO).to receive(:read).and_return(database_fixture)
      allow(Kernel).to receive(:system)
      allow(Etc).to receive(:nprocessors).and_return(number_of_processes)

      Parity::Backup.new(
        from: "production",
        to: "development",
        parallelize: true,
      ).restore

      expect(Kernel).
        to have_received(:system).
        with(make_temp_directory_command)
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
      expect(Kernel).to have_received(:system).with(set_db_metadata_sql)
    end
  end

  it "restores backups to staging from production" do
    stub_heroku_app_name
    allow(Kernel).to receive(:system)

    Parity::Backup.new(from: "production", to: "staging").restore

    expect(Kernel).
      to have_received(:system).
      with(heroku_staging_pg_reset)
    expect(Kernel).
      to have_received(:system).
      with(heroku_production_to_staging_passthrough)
  end

  it "restores backups to staging from development" do
    stub_heroku_app_name
    allow(IO).to receive(:read).and_return(database_fixture)
    allow(Kernel).to receive(:system)

    Parity::Backup.new(from: "development", to: "staging").restore

    expect(Kernel).
      to have_received(:system).
      with(heroku_staging_pg_reset)
    expect(Kernel).
      to have_received(:system).
      with(heroku_development_to_staging_passthrough)
  end

  it "passes additional arguments to the subcommand" do
    stub_heroku_app_name
    allow(Kernel).to receive(:system)

    Parity::Backup.new(
      from: "production",
      to: "staging",
      additional_args: "--confirm thisismyapp-staging",
    ).restore

    expect(Kernel).
      to have_received(:system).with(additional_argument_pass_through)
  end

  def stub_heroku_app_name
    heroku_app_name =
      instance_double(Parity::HerokuAppName, to_s: "parity-staging")
    allow(Parity::HerokuAppName).
      to receive(:new).
      with("staging").
      and_return(heroku_app_name)
  end

  def database_fixture
    IO.read(fixture_path("database.yml"))
  end

  def fixture_path(filename)
    File.join(File.dirname(__FILE__), "..", "fixtures", filename)
  end

  def drop_development_database_drop_command(db_name: default_db_name)
    "dropdb --if-exists #{db_name} && createdb #{db_name}"
  end

  def make_temp_directory_command
    "mkdir -p tmp"
  end

  def download_remote_database_command
    'curl -o tmp/latest.backup "$(heroku pg:backups:url --remote production)"'
  end

  def restore_from_local_temp_backup_command(cores: number_of_processes)
    "pg_restore tmp/latest.backup --verbose --clean --no-acl --no-owner "\
      "--dbname #{default_db_name} --jobs=#{cores} "
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

  def heroku_staging_pg_reset(basename: "parity")
    "heroku pg:reset --remote staging  --confirm #{basename}-staging"
  end

  def additional_argument_pass_through
    "heroku pg:backups:restore `heroku pg:backups:url "\
      "--remote production` DATABASE --remote staging "\
      "--confirm thisismyapp-staging"
  end

  def default_db_name
    "parity_development"
  end

  def set_db_metadata_sql
    <<-SHELL
        psql parity_development -c "CREATE TABLE IF NOT EXISTS public.ar_internal_metadata (key character varying NOT NULL, value character varying, created_at timestamp without time zone NOT NULL, updated_at timestamp without time zone NOT NULL, CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key)); UPDATE ar_internal_metadata SET value = 'development' WHERE key = 'environment'"
    SHELL
  end
end
