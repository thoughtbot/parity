require File.join(File.dirname(__FILE__), '..', 'lib', 'parity')

describe Parity::Development do
  it 'restores backups from production' do
    backup = double('backup', restore: nil)
    Parity::Backup.stub(new: backup)

    Parity::Development.new(['restore', 'production']) .run

    expect(Parity::Backup).to have_received(:new).
      with(from: 'production', to: 'development')
    expect(backup).to have_received(:restore)
  end

  it 'restores backups from staging' do
    backup = double('backup', restore: nil)
    Parity::Backup.stub(new: backup)

    Parity::Development.new(['restore', 'staging']) .run

    expect(Parity::Backup).to have_received(:new).
      with(from: 'staging', to: 'development')
    expect(backup).to have_received(:restore)
  end
end
