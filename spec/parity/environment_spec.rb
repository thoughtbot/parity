require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'parity')

RSpec.describe Parity::Environment do
  before do
    allow(Kernel).to receive(:exec).and_return(true)
    allow(Kernel).to receive(:system).and_return(true)
  end

  it "restores in parallel when passed the --parallelize flag" do
    backup = stub_parity_backup
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new(
      "development",
      ["restore", "staging", "--parallelize"],
    ).run

    expect(Parity::Backup).to have_received(:new).
      with(
        from: "staging",
        to: "development",
        parallelize: true,
        additional_args: "",
      )
    expect(backup).to have_received(:restore)
  end

  it "passes through arguments with correct quoting" do
    Parity::Environment.new(
      "production",
      ["pg:psql", "-c", "select count(*) from users;"],
    ).run

    expect(Kernel).to have_received(:exec).with(*psql_count)
  end

  it "allows connection to applications by app name rather than Git remote" do
    Parity::Environment.new(
      "my-pipeline-pr-1234",
      ["tail", "--ps", "web"],
      app_argument: "--app",
    ).run

    expect(Kernel).to have_received(:system).with(tail_pr_app)
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
        parallelize: false,
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
        parallelize: false,
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
        parallelize: false,
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
        parallelize: false,
        additional_args: "--confirm parity-staging",
      )
    expect(backup).to have_received(:restore)
  end

  it "restores backups from production to development" do
    backup = stub_parity_backup
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("development", ["restore", "production"]).run

    expect(Parity::Backup).to have_received(:new).
      with(
        from: "production",
        to: "development",
        parallelize: false,
        additional_args: "",
      )
    expect(backup).to have_received(:restore)
  end

  it "restores backups from staging to development" do
    backup = stub_parity_backup
    allow(Parity::Backup).to receive(:new).and_return(backup)

    Parity::Environment.new("development", ["restore", "staging"]).run

    expect(Parity::Backup).to have_received(:new).
      with(
        from: "staging",
        to: "development",
        parallelize: false,
        additional_args: "",
      )
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
      with(
        from: "staging",
        to: "production",
        parallelize: false,
        additional_args: "",
      )
    expect(backup).to have_received(:restore)
  end

  it "opens the remote console" do
    Parity::Environment.new("production", ["console"]).run

    expect(Kernel).to have_received(:system).with(heroku_console)
  end

  it "passes arguments to the console subcommand" do
    Parity::Environment.new("production", ["console", "--sandbox"]).run

    expect(Kernel).to have_received(:system).with(heroku_console_with_sandbox)
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

  it "returns true if deploy was successful without migrations" do
    result = Parity::Environment.new("production", ["deploy"]).run

    expect(result).to eq(true)
  end

  it "returns false if the deploy was not succesful" do
    allow(Kernel).to receive(:system).with(git_push).and_return(false)

    result = Parity::Environment.new("production", ["deploy"]).run

    expect(result).to eq(false)
  end

  it "deploys feature branches to staging's master for evaluation" do
    Parity::Environment.new("staging", ["deploy"]).run

    expect(Kernel).to have_received(:system).with(git_push_feature_branch)
  end

  it "deploys feature branches to staging's main for evaluation" do
    env = Parity::Environment.new("staging", ["deploy"])

    allow(env).to receive(:branch_ref).and_return("main")

    env.run

    expect(Kernel).to have_received(:system).with(git_push_feature_branch_main)
  end

  it "deploys main production's main for evaluation" do
    env = Parity::Environment.new("production", ["deploy"])

    allow(env).to receive(:branch_ref).and_return("main")

    env.run

    expect(Kernel).to have_received(:system).with(git_push_main)
  end

  def heroku_backup
    "heroku pg:backups:capture --remote production"
  end

  def heroku_console
    "heroku run bundle exec rails console  --remote production"
  end

  def heroku_console_with_sandbox
    "heroku run bundle exec rails console --sandbox --remote production"
  end

  def git_push
    "git push production master"
  end

  def git_push_main
    "git push production main"
  end

  def git_push_feature_branch
    "git push staging HEAD:master --force"
  end

  def git_push_feature_branch_main
    "git push staging HEAD:main --force"
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

  def tail_pr_app
    "heroku logs --tail --ps web --app my-pipeline-pr-1234"
  end

  def open
    ["heroku", "open", "--remote", "production"]
  end

  def psql_count
    [
      "heroku", "pg:psql",
      "-c", "select count(*) from users;",
      "--remote", "production"
    ]
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
