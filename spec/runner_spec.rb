# frozen_string_literal: true

RSpec.describe PubSubModelSync::Runner do
  let(:inst) { described_class.new }
  let(:connector_klass) { PubSubModelSync::Connector }
  let(:connector) { inst.connector }
  before { allow(inst.connector).to receive(:listen_messages) }
  after { inst.run }

  it '.trap_signals' do
    allow(Signal).to receive(:trap)
    expect(Signal).to receive(:trap).with('QUIT', anything)
  end

  it '.preload_framework' do
    expect(inst).to receive(:preload_framework!)
  end

  it '.start_listeners' do
    expect(connector).to receive(:listen_messages)
  end

  it 'shutdown' do
    error_klass = PubSubModelSync::Runner::ShutDown
    allow(inst).to receive(:trap_signals!).and_raise(error_klass)
    expect(connector).to receive(:stop)
  end
end
