# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bank::API::Commands::Transfer, type: :command do
  class TransferWithErrorInDebit < Bank::API::Commands::Transfer
    def create_debit_in_origin_account!
      super # ok

      raise "vixxxx"
    end
  end

  class TransferWithErrorInCredit < Bank::API::Commands::Transfer
    def create_credit_in_destination_account!
      super # ok

      raise "vixxxx"
    end
  end

  # This class do all the transactions and raises a error after, that must
  # be rescued and all the transactions must be rollbacked
  class TransferWithError < Bank::API::Commands::Transfer
    def execute_command!
      with_rollback do
        # First removes the money from the source account ("debit")
        create_debit_in_origin_account!

        # And last but not least creates the "credit" in source account
        create_credit_in_destination_account!

        raise "Some error..."
      end
    end
  end

  before :each do
    Bank::DataStore.load!  # load to reset
    Bank::DataStore.reset! # clear database
    Bank::DataStore.load!  # load it again

    @origin_customer = Bank::API::Commands.create_customer!(name: 'Origin Customer', email: 'origin@Bank.com')
    @origin_customer.account.update {|account| account.update_amount(1000) }
    @dest_customer = Bank::API::Commands.create_customer!(name: 'Dest Customer', email: 'dest@Bank.com')
    @valid_initialize_parameters = {
      origin_account: @origin_customer.account,
      destination_account: @dest_customer.account,
      amount: 10
    }

    @valid_command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters)
  end

  it 'must be initializable' do
    expect {
      Bank::API::Commands::Transfer.new(@valid_initialize_parameters)
    }.not_to raise_error
  end

  it 'must set `command_name` properly' do
    expect(@valid_command.command_name).to eq('transfer')
  end

  it 'must generate one transaction identifier' do
    expect(@valid_command.transaction_identifier).not_to be_nil
  end

  it 'must NOT regenerate the transaction identifier' do
    # to make sure they are the same when calling the method multiples times
    expect(@valid_command.transaction_identifier).to eq(@valid_command.transaction_identifier)
  end

  it 'must accept one valid `origin_account`' do
    command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters)

    expect {
      command.send(:validate_source_account!)
    }.not_to raise_error
  end

  it 'must accept one valid `destination_account`' do
    command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters)

    expect {
      command.send(:validate_destination_account!)
    }.not_to raise_error
  end

  it 'must validate the `origin_account` before execute' do
    command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters.merge(origin_account: nil))

    expect {
      command.execute!
    }.to raise_error(Bank::API::InvalidAccountNumberError)
  end

  it 'must validate the `destination_account` before execute' do
    command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters.merge(destination_account: nil))

    expect {
      command.execute!
    }.to raise_error(Bank::API::InvalidAccountNumberError)
  end

  it 'must not accept an amount lower than the minimum amount' do
    minimum = Bank::API::MINIMUM_AMOUNT_TO_BE_HANDLED
    command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters.merge(amount: minimum - 0.1))

    expect {
      command.execute!
    }.to raise_error(Bank::API::InvalidAmountError)
  end

  it 'must not accept negative amount`' do
    command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters.merge(amount: -10))

    expect {
      command.execute!
    }.to raise_error(Bank::API::InvalidAmountError)
  end

  it 'must not accept an amount higher than the amount in the origin account' do
    command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters.merge(amount: @origin_customer.account.amount + 0.1))

    expect {
      command.execute!
    }.to raise_error(Bank::API::InvalidAmountError, "There's no enough money in account for this transaction")
  end

  it 'must support rollback' do
    command = TransferWithError.new(@valid_initialize_parameters.merge(amount: 500))

    # Before sending the money
    expect(command.origin_account.amount).to eq(1000)
    expect(command.destination_account.amount).to eq(0)

    # try to send the money, but some error will happens
    command.execute!

    # Before trying to send the money...but some error ocurrs
    expect(command.origin_account.amount).to eq(1000)
    expect(command.destination_account.amount).to eq(0)
  end

  it 'must properly execute the transactions between accounts' do
    command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters.merge(amount: 99.92))

    # Before sending the money
    expect(command.origin_account.amount).to eq(1000)
    expect(command.destination_account.amount).to eq(0)

    # try to send the money
    command.execute!

    # Before trying to send the money...but some error ocurrs
    expect(command.origin_account.amount).to eq(900.08)
    expect(command.destination_account.amount).to eq(99.92)
  end

  it 'must not execute the transactions twice' do
    command = Bank::API::Commands::Transfer.new(@valid_initialize_parameters.merge(amount: 99.92))

    # Before sending the money
    expect(command.origin_account.amount).to eq(1000)
    expect(command.destination_account.amount).to eq(0)

    # try to send the money 10 times in a row
    10.times { command.execute! }

    # Before trying to send the money...but some error ocurrs
    expect(command.origin_account.amount).to eq(900.08)
    expect(command.destination_account.amount).to eq(99.92)
  end

  it 'must normalize the numbers as BigDecimal' do
    expect(@valid_command.send(:normalize_amount, 1)).to be_a(BigDecimal)
  end

  it 'must correctly substract values' do
    expect(@valid_command.send(:subtract_values, 999.3, 99.1).to_f).to eq(900.2)
  end

  it 'must correctly add values' do
    expect(@valid_command.send(:add_values, 900.3, 99.1).to_f).to eq(999.4)
  end

  it 'must properly validate if it should `rollback_debit?`' do
    command = TransferWithErrorInDebit.new(@valid_initialize_parameters.merge(amount: 500))

    # before the transaction
    expect(command.rollback_debit?).to be_falsey
    # execute it
    command.execute!

    # After the transaction execution(with error)
    expect(command.rollback_debit?).to be_truthy
  end

  it 'must set `@debit_rollbacked` after debit rollback when error ocurrs' do
    command = TransferWithErrorInDebit.new(@valid_initialize_parameters.merge(amount: 500))

    # before the transaction
    expect(command.instance_variable_get('@debit_rollbacked')).to be_nil
    # execute it
    command.execute!

    # After the transaction execution(with error)
    expect(command.instance_variable_get('@debit_rollbacked')).to be_truthy
  end

  it 'must properly validate if it should `rollback_credit?`' do
    command = TransferWithErrorInCredit.new(@valid_initialize_parameters.merge(amount: 500))

    # before the transaction
    expect(command.rollback_credit?).to be_falsey
    # execute it
    command.execute!

    # After the transaction execution(with error)
    expect(command.rollback_credit?).to be_truthy
  end

  it 'must set `@credit_rollbacked` after credit rollback when error ocurrs' do
    command = TransferWithErrorInCredit.new(@valid_initialize_parameters.merge(amount: 500))

    # before the transaction
    expect(command.instance_variable_get('@credit_rollbacked')).to be_nil
    # execute it
    command.execute!

    # After the transaction execution(with error)
    expect(command.instance_variable_get('@credit_rollbacked')).to be_truthy
  end
end