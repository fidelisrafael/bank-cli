# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bank::API::Commands::CheckBalance, type: :command do
  before :each do
    Bank::DataStore.load!  # load to reset
    Bank::DataStore.reset! # clear database
    Bank::DataStore.load!  # load it again

    @origin_customer = Bank::API::Commands.create_customer!(name: 'Origin Customer', email: 'origin@Bank.com')
    @origin_customer.account.update {|account| account.update_amount(888.88) }
  end

  it 'must be initializable' do
    expect {
      Bank::API::Commands::CheckBalance.new(origin_account: @origin_customer.account)
    }.not_to raise_error
  end

  it 'must set `command_name` properly' do
    command = Bank::API::Commands::CheckBalance.new(origin_account: @origin_customer.account)

    expect(command.command_name).to eq('check_balance')
  end

  it 'must accept one valid `origin_account`' do
    command = Bank::API::Commands::CheckBalance.new(origin_account: @origin_customer.account)

    expect {
      command.send(:validate_source_account!)
    }.not_to raise_error
  end

  it 'must validate the `origin_account` before execute' do
    command = Bank::API::Commands::CheckBalance.new(origin_account: nil)

    expect {
      command.execute!
    }.to raise_error(Bank::API::InvalidAccountNumberError)
  end

  it 'must save the current amount in the account in `amount`' do
    command = Bank::API::Commands::CheckBalance.new(origin_account: @origin_customer.account)

    expect(command.amount).to be_nil
    command.execute!

    expect(command.amount).to eq(@origin_customer.account.amount)
  end

  it 'must execute the action with success' do
    command = Bank::API::Commands::CheckBalance.new(origin_account: @origin_customer.account)
    command.execute!

    expect(command.success?).to be_truthy
  end

  it 'must execute action without errors' do
    command = Bank::API::Commands::CheckBalance.new(origin_account: @origin_customer.account)
    command.execute!

    expect(command.error?).to be_falsey
  end
end