require File.join(File.dirname(__FILE__), "..", "lib", "parity")

describe Parity::Environment do
  it "passes through arguments with correct quoting" do
    allow(Kernel).to receive(:system)

    Parity::Environment.new(
      "production",
      ["pg:psql", "-c", "select count(*) from users;"]
    ).run

    expect(Kernel).to have_received(:system).with(*psql_count)
  end

  it "backs up the database" do
    allow(Kernel).to receive(:system)

    Parity::Environment.new("production", ["backup"]).run

    expect(Kernel).to have_received(:system).with(heroku_backup)
  end

  it "restores backups from production to staging" do
    backup = double("backup", restore: nil)
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("staging", ["restore", "production"]).run

    expect(Parity::Backup).to have_received(:new).
      with(from: "production", to: "staging", additional_args: "")
    expect(backup).to have_received(:restore)
  end

  it "passes arguments to the restore command when used against staging" do
    backup = double("backup", restore: nil)
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new(
      "staging",
      ["restore", "production", "--confirm", "myappname-staging"]
    ).run

    expect(Parity::Backup).to have_received(:new).
      with(
        from: "production",
        to: "staging",
        additional_args: "--confirm myappname-staging"
      )
    expect(backup).to have_received(:restore)
  end

  it "restores backups from production to development" do
    backup = double("backup", restore: nil)
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("development", ["restore", "production"]).run

    expect(Parity::Backup).to have_received(:new).
      with(from: "production", to: "development", additional_args: "")
    expect(backup).to have_received(:restore)
  end

  it "restores backups from staging to development" do
    backup = double("backup", restore: nil)
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("development", ["restore", "staging"]).run

    expect(Parity::Backup).to have_received(:new).
      with(from: "staging", to: "development", additional_args: "")
    expect(backup).to have_received(:restore)
  end

  it "does not allow restoring backups into production" do
    backup = double("backup", restore: nil)
    allow(Parity::Backup).to receive(:new).and_return(backup)
    allow($stdout).to receive(:puts)

    Parity::Environment.new("production", ["restore", "staging"]).run

    expect(Parity::Backup).not_to have_received(:new)
    expect($stdout).to have_received(:puts).
      with("Parity does not support restoring backups into your production environment.")
  end

  it "opens the remote console" do
    allow(Kernel).to receive(:system)

    Parity::Environment.new("production", ["console"]).run

    expect(Kernel).to have_received(:system).with(heroku_console)
  end

  it "automatically restarts processes when it migrates the database" do
    allow(Kernel).to receive(:system)

    Parity::Environment.new("production", ["migrate"]).run

    expect(Kernel).to have_received(:system).with(migrate)
  end

  it "tails logs with any additional arguments" do
    allow(Kernel).to receive(:system)

    Parity::Environment.new("production", ["tail", "--ps", "web"]).run

    expect(Kernel).to have_received(:system).with(tail)
  end

  it "opens the app" do
    allow(Kernel).to receive(:system)

    Parity::Environment.new("production", ["open"]).run

    expect(Kernel).to have_received(:system).with(*open)
  end

  it "opens a Redis session connected to the environment's Redis service" do
    allow(Open3).to receive(:capture3).and_return(open3_redis_url_fetch_result)
    allow(Kernel).to receive(:system)

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

  it "deploys the application and runs migrations when required" do
    allow(Kernel).to receive(:system)
    allow(Kernel).to receive(:system).with(git_push).and_return(true)
    allow(Kernel).to receive(:system).with(skip_migration).and_return(false)

    Parity::Environment.new("production", ["deploy"]).run

    expect(Kernel).to have_received(:system).with(git_push)
    expect(Kernel).to have_received(:system).with(skip_migration)
    expect(Kernel).to have_received(:system).with(migrate)
  end

  it "deploys the application and skips migrations when not required" do
    allow(Kernel).to receive(:system)
    allow(Kernel).to receive(:system).with(git_push).and_return(true)
    allow(Kernel).to receive(:system).with(skip_migration).and_return(true)

    Parity::Environment.new("production", ["deploy"]).run

    expect(Kernel).to have_received(:system).with(git_push)
    expect(Kernel).to have_received(:system).with(skip_migration)
    expect(Kernel).not_to have_received(:system).with(migrate)
  end

  it "does not run migrations if the deploy failed" do
    allow(Kernel).to receive(:system)
    allow(Kernel).to receive(:system).with(git_push).and_return(false)
    allow(Kernel).to receive(:system).with(skip_migration).and_return(false)

    Parity::Environment.new("production", ["deploy"]).run

    expect(Kernel).to have_received(:system).with(git_push)
    expect(Kernel).not_to have_received(:system).with(migrate)
  end

  it "deploys feature branches to staging's master for evaluation" do
    allow(Kernel).to receive(:system)

    Parity::Environment.new("staging", ["deploy"]).run

    expect(Kernel).to have_received(:system).with(git_push_feature_branch)
  end

  def heroku_backup
    "heroku pg:backups capture --remote production"
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

  def skip_migration
      %{
        git fetch production &&
        git diff --quiet production/master..master -- db/migrate
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
end
