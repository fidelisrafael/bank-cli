# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bank::API::Validator, type: :command do
  before :each do
    Bank::DataStore.load!  # load to reset
    Bank::DataStore.reset! # clear database
    Bank::DataStore.load!  # load it again

    @origin_customer = Bank::API::Commands.create_customer!(name: 'Origin Customer', email: 'origin@Bank.com')
    @dest_customer = Bank::API::Commands.create_customer!(name: 'Dest Customer', email: 'dest@Bank.com')
    # Add some credits
    @origin_customer.account.update {|account| account.update_amount(1000) }
  end

  it 'must properly validate if a command is valid' do
    expect(subject.valid_command?(:transfer)).to be_truthy
    expect(subject.valid_command?(:check_balance)).to be_truthy
    expect(subject.valid_command?(SecureRandom.hex)).to be_falsey
  end

  it 'must validate if a account id is valid' do
    expect(subject.valid_account_id?('1234')).to be_truthy
    expect(subject.valid_account_id?('')).to be_falsey
    expect(subject.valid_account_id?(nil)).to be_falsey
    expect(subject.valid_account_id?('   ')).to be_falsey
  end

  it 'must validate if a account id is empty' do
    expect(subject.empty_account_id?('1234')).to be_falsey
    expect(subject.empty_account_id?('')).to be_truthy
    expect(subject.empty_account_id?(nil)).to be_truthy
    expect(subject.empty_account_id?('   ')).to be_truthy
  end

  it 'must validate the minimum amount to be handled within the application' do
    expect(subject.valid_minimum_amount?(-1)).to be_falsey
    expect(subject.valid_minimum_amount?(0)).to be_falsey
    expect(subject.valid_minimum_amount?(0.1)).to be_truthy
    expect(subject.valid_minimum_amount?(1)).to be_truthy
  end

  it 'must raise an Error if two accounts ids are the same' do
    expect { 
      subject.validate_accounts_id!('0001', '0001')
    }.to raise_error(Bank::API::SameAccountError)
  end

  it 'must raise an Error if the command are not valid' do
    expect {
      subject.validate_command!(:not_existing_command)
    }.to raise_error(Bank::API::InvalidCommandError)
  end

  it 'must raise an Error if the account is not valid' do
    expect {
      subject.validate_account!(nil)
    }.to raise_error(Bank::API::InvalidAccountNumberError, 'This account is invalid')
  end

  it 'must raise an Error if the destination account is not valid' do
    expect {
      subject.validate_destination_account!(nil)
    }.to raise_error(Bank::API::InvalidAccountNumberError, 'The destination account ID is not valid')
  end

  it 'must raise an Error if the origin account is not valid' do
    expect {
      subject.validate_source_account!(nil)
    }.to raise_error(Bank::API::InvalidAccountNumberError, 'The source account ID is not valid')
  end

  it 'must raise an Error if the minimum amount is not valid' do
    expect {
      subject.validate_minimum_amount!(0)
    }.to raise_error(Bank::API::InvalidAmountError)
  end

end