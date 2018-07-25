# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/bank/cli'

RSpec.describe Bank::CLI, type: :cli do
  before :all do
    RSpec::Expectations.configuration.on_potential_false_positives = :nothing
  end

  after :all do
    RSpec::Expectations.configuration.on_potential_false_positives = :warn
  end

  it 'should not start! from the CLI with a invalid command name' do
    expect {
      subject.start!(command_name: 'not_existing')
    }.to raise_error(Bank::API::InvalidCommandError)
  end

  it 'should start! from the CLI with a valid command name' do
    expect {
      # This will raise another error (related to data validation, but not the command)
      subject.start!(command_name: 'check_balance')
    }.not_to raise_error(Bank::API::InvalidCommandError)
  end

  it 'should load the database after start!' do
    expect {
      # This will raise another error (related to data validation, but not the command)
      subject.start!(command_name: 'check_balance')
    }.not_to raise_error(Bank::API::InvalidCommandError)

    expect(Bank::DataStore.loaded?).to be_truthy
  end
end