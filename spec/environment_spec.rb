require File.join(File.dirname(__FILE__), "..", "lib", "parity")

describe Parity::Environment do
  it "backs up the database" do
    Kernel.stub(:system)

    Parity::Environment.new("production", ["backup"]).run

    expect(Kernel).to have_received(:system).with(heroku_backup)
  end

  it "restores backups from production to staging" do
    backup = double("backup", restore: nil)
    Parity::Backup.stub(new: backup)

    Parity::Environment.new("staging", ["restore", "production"]).run

    expect(Parity::Backup).to have_received(:new).
      with(from: "production", to: "staging")
    expect(backup).to have_received(:restore)
  end

  it "restores backups from production to development" do
    backup = double("backup", restore: nil)
    Parity::Backup.stub(new: backup)

    Parity::Environment.new("development", ["restore", "production"]).run

    expect(Parity::Backup).to have_received(:new).
      with(from: "production", to: "development")
    expect(backup).to have_received(:restore)
  end

  it "restores backups from staging to development" do
    backup = double("backup", restore: nil)
    Parity::Backup.stub(new: backup)

    Parity::Environment.new("development", ["restore", "staging"]).run

    expect(Parity::Backup).to have_received(:new).
      with(from: "staging", to: "development")
    expect(backup).to have_received(:restore)
  end

  it "does not allow restoring backups into production" do
    backup = double("backup", restore: nil)
    Parity::Backup.stub(new: backup)
    $stdout.stub(:puts)

    Parity::Environment.new("production", ["restore", "staging"]).run

    expect(Parity::Backup).not_to have_received(:new)
    expect($stdout).to have_received(:puts).
      with("Parity does not support restoring backups into your production environment.")
  end

  it "opens the remote console" do
    Kernel.stub(:system)

    Parity::Environment.new("production", ["console"]).run

    expect(Kernel).to have_received(:system).with(heroku_console)
  end

  it "opens the log2viz visualization" do
    Kernel.stub(:system)

    Parity::Environment.new("production", ["log2viz"]).run

    expect(Kernel).to have_received(:system).with(heroku_log2viz)
  end

  it "automatically restarts processes when it migrates the database" do
    Kernel.stub(:system)

    Parity::Environment.new("production", ["migrate"]).run

    expect(Kernel).to have_received(:system).with(migrate)
  end

  it "tails logs with any additional arguments" do
    Kernel.stub(:system)

    Parity::Environment.new("production", ["tail", "--ps", "web"]).run

    expect(Kernel).to have_received(:system).with(tail)
  end

  it "opens the app" do
    Kernel.stub(:system)

    Parity::Environment.new("production", ["open"]).run

    expect(Kernel).to have_received(:system).with(open)
  end

  it "opens a Redis session connected to the environment's Redis service" do
    Parity.configure do |config|
      config.redis_url_env_variable = "MYREDIS_URL"
    end
    Open3.stub(:capture3).and_return(open3_redis_url_fetch_result)
    Kernel.stub(:system)

    Parity::Environment.new("production", ["redis_cli"]).run

    expect(Kernel).to have_received(:system).with(redis_cli)
    expect(Open3).
      to have_received(:capture3).
      with(fetch_redis_url).
      once
  end

  def heroku_backup
    "heroku pgbackups:capture --expire --remote production"
  end

  def heroku_console
    "heroku run rails console --remote production"
  end

  def heroku_log2viz
    "open https://log2viz.herokuapp.com/app/parity-production"
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
    "heroku open --remote production"
  end

  def redis_cli
    "redis-cli -h landshark.redistogo.com -p 90210 -a abcd1234efgh5678"
  end

  def fetch_redis_url
    "heroku config:get MYREDIS_URL --remote production"
  end

  def open3_redis_url_fetch_result
    [
      "redis://redistogo:abcd1234efgh5678@landshark.redistogo.com:90210/\n",
      "",
      ""
    ]
  end
end
