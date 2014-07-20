require File.join(File.dirname(__FILE__), '..', 'lib', 'parity')

describe Parity::Environment do
  it 'backs up the database' do
    Kernel.stub(:system)

    Parity::Environment.new('production', ['backup']).run

    expect(Kernel).to have_received(:system).with(heroku_backup)
  end

  it 'opens the remote console' do
    Kernel.stub(:system)

    Parity::Environment.new('production', ['console']).run

    expect(Kernel).to have_received(:system).with(heroku_console)
  end

  it 'opens the log2viz visualization' do
    Kernel.stub(:system)

    Parity::Environment.new('production', ['log2viz']).run

    expect(Kernel).to have_received(:system).with(heroku_log2viz)
  end

  it 'automatically restarts processes when it migrates the database' do
    Kernel.stub(:system)

    Parity::Environment.new('production', ['migrate']).run

    expect(Kernel).to have_received(:system).with(migrate)
  end

  it 'tails logs' do
    Kernel.stub(:system)

    Parity::Environment.new('production', ['tail']).run

    expect(Kernel).to have_received(:system).with(tail)
  end

  it 'opens the app' do
    Kernel.stub(:system)

    Parity::Environment.new('production', ['open']).run

    expect(Kernel).to have_received(:system).with(open)
  end

  it 'runs rake' do
    Kernel.stub(:system)

    Parity::Environment.new('production', ['rake', 'purge']).run

    expect(Kernel).to have_received(:system).with(rake_purge)
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

  def rake_purge
    "heroku run rake purge --remote production"
  end

  def tail
    "heroku logs --tail --remote production"
  end

  def open
    "heroku open --remote production"
  end
end
