require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'parity')

describe Parity::Usage do
  it 'cuts the Usage section out of the README' do
    usage = Parity::Usage.new.to_s

    expect(usage).to match(/The scripts also pass through/)
    expect(usage).to match(/staging open/)
    expect(usage).not_to match(/Install/)
    expect(usage).not_to match(/Convention/)
  end
end
