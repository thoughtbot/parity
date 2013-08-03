require File.join(File.dirname(__FILE__), '..', 'lib', 'parity')

describe Parity::Staging do
  it 'restores backups from production' do
    backup = double('backup', restore: nil)
    Parity::Backup.stub(new: backup)

    Parity::Staging.new(['restore', 'production']).run

    expect(Parity::Backup).to have_received(:new).
      with(from: 'production', to: 'staging')
    expect(backup).to have_received(:restore)
  end
end
