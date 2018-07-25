# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bank::API::Commands, type: :command do
  before :each do
    Bank::DataStore.load!  # load to reset
    Bank::DataStore.reset! # clear database
    Bank::DataStore.load!  # load it again

    @origin_customer = Bank::API::Commands.create_customer!(name: 'Origin Customer', email: 'origin@Bank.com')
    @dest_customer = Bank::API::Commands.create_customer!(name: 'Dest Customer', email: 'dest@Bank.com')
    # Add some credits
    @origin_customer.account.update {|account| account.update_amount(1000) }
  end

  it 'must have the command to transfer money between accounts' do
    expect(subject.method_defined?(:transfer!))
  end

  it 'should transfer money between accounts' do
    # Before sending the money
    expect(@origin_customer.account.amount).to eq(1000)
    expect(@dest_customer.account.amount).to eq(0)

    subject.transfer!(@origin_customer.account.id, @dest_customer.account.id, 10)

    # Some code to proper reload the associations and the data
    Bank::DataStore.reload!
    # Clearing the current associated accounts to fetch the new ones
    @origin_customer.instance_variable_set('@account', nil)
    @dest_customer.instance_variable_set('@account', nil)

    # After the transfer
    expect(@origin_customer.account.amount).to eq(990.00)
    expect(@dest_customer.account.amount).to eq(10)
  end

  # The others more specific tests are included in `commands/transfer_command_spec.rb`
  it 'should not transfer money between the accounts when the data is invalid' do
    # Before sending the money
    expect(@origin_customer.account.amount).to eq(1000)
    expect(@dest_customer.account.amount).to eq(0)

    expect {
      subject.transfer!(@origin_customer.account.id, '', 10)
    }.to raise_error(Bank::API::InvalidAccountNumberError)

    # Some code to proper reload the associations and the data
    Bank::DataStore.reload!
    # Clearing the current associated accounts to fetch the new ones
    @origin_customer.instance_variable_set('@account', nil)
    @dest_customer.instance_variable_set('@account', nil)

    # After the transfer
    expect(@origin_customer.account.amount).to eq(1000.00)
    expect(@dest_customer.account.amount).to eq(0)
  end

  it "should allow to check account's balance after transfering" do
    # Before sending the money
    expect(@origin_customer.account.amount).to eq(1000)
    expect(@dest_customer.account.amount).to eq(0)

    subject.transfer!(@origin_customer.account.id, @dest_customer.account.id, 10)

    dest_account_command = subject.check_balance!(@dest_customer.account.id)
    origin_account_command = subject.check_balance!(@origin_customer.account.id)

    expect(dest_account_command.amount).to eq(10)
    expect(origin_account_command.amount).to eq(990.00)
  end
end