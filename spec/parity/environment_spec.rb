require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'parity')

RSpec.describe Parity::Environment do
  before do
    allow(Kernel).to receive(:exec).and_return(true)
    allow(Kernel).to receive(:system).and_return(true)
  end

  it "passes through arguments with correct quoting" do
    Parity::Environment.new(
      "production",
      ["pg:psql", "-c", "select count(*) from users;"],
    ).run

    expect(Kernel).to have_received(:exec).with(*psql_count)
  end

  it "returns `false` when a system command fails" do
    allow(Kernel).to receive(:exec).with(*psql_count).and_return(nil)

    result = Parity::Environment.new(
      "production",
      ["pg:psql", "-c", "select count(*) from users;"],
    ).run

    expect(result).to eq(false)
  end

  it "backs up the database" do
    Parity::Environment.new("production", ["backup"]).run

    expect(Kernel).to have_received(:system).with(heroku_backup)
  end

  it "connects to the Heroku app when $PWD does not match the app name" do
    backup = stub_parity_backup
    stub_git_remote(base_name: "parity-integration", environment: "staging")
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("staging", ["restore", "production"]).run

    expect(Parity::Backup).
      to have_received(:new).
      with(
        from: "production",
        to: "staging",
        additional_args: "--confirm parity-integration-staging",
      )
    expect(backup).to have_received(:restore)
  end

  it "restores backups from production to staging" do
    backup = stub_parity_backup
    stub_git_remote(environment: "staging")
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("staging", ["restore", "production"]).run

    expect(Parity::Backup).
      to have_received(:new).
      with(
        from: "production",
        to: "staging",
        additional_args: "--confirm parity-staging",
      )
    expect(backup).to have_received(:restore)
  end

  it "restores using restore-from" do
    backup = stub_parity_backup
    stub_git_remote(environment: "staging")
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("staging", ["restore-from", "production"]).run

    expect(Parity::Backup).
      to have_received(:new).
      with(
        from: "production",
        to: "staging",
        additional_args: "--confirm parity-staging",
      )
    expect(backup).to have_received(:restore)
  end

  it "passes the confirm argument when restoring to a non-prod environment" do
    backup = stub_parity_backup
    stub_git_remote(environment: "staging")
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("staging", ["restore", "production"]).run

    expect(Parity::Backup).to have_received(:new).
      with(
        from: "production",
        to: "staging",
        additional_args: "--confirm parity-staging",
      )
    expect(backup).to have_received(:restore)
  end

  it "restores backups from production to development" do
    backup = stub_parity_backup
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("development", ["restore", "production"]).run

    expect(Parity::Backup).to have_received(:new).
      with(from: "production", to: "development", additional_args: "")
    expect(backup).to have_received(:restore)
  end

  it "restores backups from staging to development" do
    backup = stub_parity_backup
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("development", ["restore", "staging"]).run

    expect(Parity::Backup).to have_received(:new).
      with(from: "staging", to: "development", additional_args: "")
    expect(backup).to have_received(:restore)
  end

  it "does not allow restoring backups into production" do
    backup = stub_parity_backup
    stub_git_remote
    allow(Parity::Backup).to receive(:new).and_return(backup)
    allow($stdout).to receive(:puts)

    Parity::Environment.new("production", ["restore", "staging"]).run

    expect(Parity::Backup).not_to have_received(:new)
    expect($stdout).to have_received(:puts).
      with("Parity does not support restoring backups into your production "\
           "environment. Use `--force` to override.")
  end

  it "restores backups into production if forced" do
    backup = stub_parity_backup
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("production", ["restore", "staging", "--force"]).run

    expect(Parity::Backup).to have_received(:new).
      with(from: "staging", to: "production", additional_args: "")
    expect(backup).to have_received(:restore)
  end

  it "opens the remote console" do
    Parity::Environment.new("production", ["console"]).run

    expect(Kernel).to have_received(:system).with(heroku_console)
  end

  it "automatically restarts processes when it migrates the database" do
    Parity::Environment.new("production", ["migrate"]).run

    expect(Kernel).to have_received(:system).with(migrate)
  end

  it "tails logs with any additional arguments" do
    Parity::Environment.new("production", ["tail", "--ps", "web"]).run

    expect(Kernel).to have_received(:system).with(tail)
  end

  it "opens the app" do
    Parity::Environment.new("production", ["open"]).run

    expect(Kernel).to have_received(:exec).with(*open)
  end

  it "opens a Redis session connected to the environment's Redis service" do
    allow(Open3).to receive(:capture3).and_return(open3_redis_url_fetch_result)

    Parity::Environment.new("production", ["redis_cli"]).run

    expect(Kernel).to have_received(:system).with(
      "redis-cli",
      "-h",
      "landshark.redistogo.com",
      "-p",
      "90210",
      "-a",
      "abcd1234efgh5678"
    )
    expect(Open3).
      to have_received(:capture3).
      with(fetch_redis_url("REDIS_URL")).
      once
  end

  describe "database migration on deploy" do
    it "deploys the application and runs migrations when required" do
      stub_is_a_rails_app
      allow(Kernel).
        to receive(:system).
        with(check_for_no_pending_migrations).
        and_return(false)

      Parity::Environment.new("production", ["deploy"]).run

      expect(Kernel).
        to have_received(:system).
        with(check_for_no_pending_migrations).
        ordered
      expect(Kernel).to have_received(:system).with(git_push).ordered
      expect(Kernel).to have_received(:system).with(migrate).ordered
    end

    it "deploys the application and skips migrations when not required" do
      stub_is_a_rails_app
      allow(Kernel).
        to receive(:system).
        with(check_for_no_pending_migrations).
        and_return(true)

      Parity::Environment.new("production", ["deploy"]).run

      expect(Kernel).to have_received(:system).with(git_push)
      expect(Kernel).not_to have_received(:system).with(migrate)
    end

    context "when deploying to a non-production environment" do
      it "compares against HEAD to check for pending migrations" do
        stub_is_a_rails_app
        allow(Kernel).
          to receive(:system).
          with(check_for_no_pending_migrations).
          and_return(false)

        Parity::Environment.new("staging", ["deploy"]).run

        expect(Kernel).
          to have_received(:system).
          with(
            check_for_no_pending_migrations(
              compare_with: "HEAD",
              environment: "staging",
            )
          ).ordered
      end
    end
  end

  it "returns true if the deploy was succesful but no migrations needed to be run" do
    stub_is_a_rails_app
    allow(Kernel).
      to receive(:system).
      with(check_for_no_pending_migrations).
      and_return(true)

    result = Parity::Environment.new("production", ["deploy"]).run

    expect(result).to eq(true)
  end

  it "returns false if the deploy was not succesful" do
    stub_is_a_rails_app
    allow(Kernel).to receive(:system).with(git_push).and_return(false)

    result = Parity::Environment.new("production", ["deploy"]).run

    expect(result).to eq(false)
  end

  it "does not run migrations if the deploy failed" do
    stub_is_a_rails_app
    allow(Kernel).
      to receive(:system).
      with(check_for_no_pending_migrations).
      and_return(false)
    allow(Kernel).to receive(:system).with(git_push).and_return(false)

    Parity::Environment.new("production", ["deploy"]).run

    expect(Kernel).not_to have_received(:system).with(migrate)
  end

  it "does not run migrations if no Rakefile is present" do
    stub_migration_path_check(true)
    stub_rakefile_check(false)

    Parity::Environment.new("production", ["deploy"]).run

    expect(Kernel).not_to have_received(:system).with(migrate)
  end

  it "does not run migrations if no db/migrate directory is present" do
    path_stub = stub_migration_path_check(false)
    stub_rakefile_check(true)

    Parity::Environment.new("production", ["deploy"]).run

    expect(path_stub).to have_received(:join).with("migrate").ordered
    expect(path_stub).to have_received(:directory?).ordered
    expect(Kernel).not_to have_received(:system).with(migrate)
  end

  it "deploys feature branches to staging's master for evaluation" do
    Parity::Environment.new("staging", ["deploy"]).run

    expect(Kernel).to have_received(:system).with(git_push_feature_branch)
  end

  def heroku_backup
    "heroku pg:backups:capture --remote production"
  end

  def heroku_console
    "heroku run rails console --remote production"
  end

  def git_push
    "git push production master"
  end

  def git_push_feature_branch
    "git push staging HEAD:master --force"
  end

  def check_for_no_pending_migrations(compare_with: "master", environment: "production")
      %{
        git fetch #{environment} &&
        git diff --quiet #{environment}/master..#{compare_with} -- db/migrate
      }
  end

  def migrate
      %{
        heroku run rake db:migrate --remote production &&
        heroku restart --remote production
      }
  end

  def tail
    "heroku logs --tail --ps web --remote production"
  end

  def open
    ["heroku", "open", "--remote", "production"]
  end

  def redis_cli
    "redis-cli -h landshark.redistogo.com -p 90210 -a abcd1234efgh5678"
  end

  def fetch_redis_url(env_variable)
    "heroku config:get #{env_variable} --remote production"
  end

  def open3_redis_url_fetch_result
    [
      "redis://redistogo:abcd1234efgh5678@landshark.redistogo.com:90210/\n",
      "",
      ""
    ]
  end

  def psql_count
    [
      "heroku", "pg:psql",
      "-c", "select count(*) from users;",
      "--remote", "production"
    ]
  end

  def stub_is_a_rails_app
    stub_rakefile_check(true)
    stub_migration_path_check(true)
  end

  def stub_rakefile_check(result)
    allow(File).to receive(:exists?).with("Rakefile").and_return(result)
  end

  def stub_migration_path_check(result)
    path_stub = spy("Pathname", directory?: result)
    allow(Pathname).to receive(:new).with("db").and_return(path_stub)

    path_stub
  end

  def stub_git_remote(base_name: "parity", environment: "staging")
    heroku_app_name = instance_double(
      Parity::HerokuAppName,
      to_s: "#{base_name}-#{environment}",
    )
    allow(Parity::HerokuAppName).
      to receive(:new).
      with(environment).
      and_return(heroku_app_name)
  end

  def stub_parity_backup
    instance_double("Parity::Backup", restore: nil)
  end
end
