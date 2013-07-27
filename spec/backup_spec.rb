require File.join(File.dirname(__FILE__), '..', 'lib', 'parity')

describe Parity::Backup do
  it 'restores backups to development' do
    Parity.configure do |config|
      config.database_config_path = database_config_path
    end

    Kernel.stub(:system)

    Parity::Backup.new(from: 'production', to: 'development').restore

    expect(Kernel).to have_received(:system).with(curl_piped_to_pg_restore)
  end

  it 'restores backups to staging' do
    Kernel.stub(:system)

    Parity::Backup.new(from: 'production', to: 'staging').restore

    expect(Kernel).to have_received(:system).with(heroku_pass_through)
  end

  def database_config_path
    File.join(File.dirname(__FILE__), 'fixtures', 'database.yml')
  end

  def curl_piped_to_pg_restore
    "curl -s `heroku pgbackups:url --remote production` | #{pg_restore}"
  end

  def pg_restore
    "pg_restore --verbose --clean --no-acl --no-owner -d parity_development"
  end

  def heroku_pass_through
    "heroku pgbackups:restore DATABASE `heroku pgbackups:url --remote production` --remote staging"
  end
end
