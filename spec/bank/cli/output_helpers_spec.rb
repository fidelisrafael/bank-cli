# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/bank/cli'

RSpec.describe Bank::CLI::OutputHelpers, type: :cli do
  module TestOutputHelpersModule
    extend Bank::CLI::OutputHelpers
  end

  before :each do
    Bank::DataStore.load!  # load to reset
  end

  after :each do
    Bank::DataStore.reset! # clear database
  end

  it 'must properly format values in Real' do
    expect(TestOutputHelpersModule.format_value(1000)).to eq('R$ 10.0')
    expect(TestOutputHelpersModule.format_value(1020)).to eq('R$ 10.2')
    expect(TestOutputHelpersModule.format_value(0)).to eq('R$ 0.0')
    expect(TestOutputHelpersModule.format_value(9999999)).to eq('R$ 99999.99')
    expect(TestOutputHelpersModule.format_value(0.1)).to eq('R$ 0.001')
  end

  it 'must format execution time in ms' do
    expect(TestOutputHelpersModule.format_execution_time(1000)).to eq('1000.00 ms')
    expect(TestOutputHelpersModule.format_execution_time(10)).to eq('10.00 ms')
    expect(TestOutputHelpersModule.format_execution_time(0)).to eq('0.00 ms')
    expect(TestOutputHelpersModule.format_execution_time(1)).to eq('1.00 ms')
  end

  it 'should properly generates the transaction summary for #transfer command' do
    options = {
      command_name: :transfer,
      origin_account_id: 'abc1',
      origin_customer_email: 'rafa_fidelis@yahoo.com.br',
      destination_account_id: 'cba1',
      destination_customer_email: 'another@person.com',
      amount: 1000
    }

    time = Time.new(2018, 07, 20, 14, 21, 20)

    expected_summary = <<~SUMMARY
      Please, review your transaction.

      Operation: Transfer beetwen two accounts.

      Date: 20/07/2018 14:21:20
      Source's account: 'abc1'
      Destination's account: 'cba1'
      Amount: R$ 10.0
    SUMMARY

    summary = TestOutputHelpersModule.generate_transaction_summary(options, time)

    expect(summary).to eq(expected_summary)
  end

  it 'should properly generates the transaction summary for #check_balance command' do
    options = {
      command_name: :check_balance,
      origin_account_id: 'abc1',
    }

    time = Time.new(2018, 07, 20, 14, 21, 20)

    expected_summary = <<~SUMMARY
      Please, review your transaction.

      Operation: Balance checking.

      Date: 20/07/2018 14:21:20
      Source's account: 'abc1'
    SUMMARY

    summary = TestOutputHelpersModule.generate_transaction_summary(options, time)

    expect(summary).to eq(expected_summary)
  end

  it 'must proper generate the receipt for a successfully #transfer command object' do
    origin_customer = Bank::API::Commands.create_customer!(name: 'Origin Customer', email: 'origin@Bank.com')
    origin_customer.account.update {|account| account.update_amount(1000) }
    dest_customer = Bank::API::Commands.create_customer!(name: 'Dest Customer', email: 'dest@Bank.com')

    options = {
      origin_account: origin_customer.account,
      destination_account: dest_customer.account,
      amount: 910
    }

    command = Bank::API::Commands::Transfer.new(options)
    command.execute!

    expected_receipt = <<~RECEIPT
      Operation: Money transfer between accounts.
      Status: Transaction completed successfully

      Date: #{TestOutputHelpersModule.format_time(command.finished_at)}
      Source's account: '#{command.origin_account.id}' (#{command.origin_account.customer.email})
      Destination's account: '#{command.destination_account.id}' (#{command.destination_account.customer.email})
      Amount: R$ 9.1
      Transaction Identifier: #{command.transaction_identifier}
      Execution time: #{TestOutputHelpersModule.format_execution_time(command.execution_time)}

      Bank 2018
    RECEIPT

    receipt = TestOutputHelpersModule.generate_receipt_for_command(command)

    # Remove all output characters that colorizes string
    expect(receipt.gsub(/(\e\[.{,2})/, '')).to eq(expected_receipt)
  end

  it 'must proper generate the receipt for a successfully #check_balance command object' do
    origin_customer = Bank::API::Commands.create_customer!(name: 'Origin Customer', email: 'origin@Bank.com')
    origin_customer.account.update {|account| account.update_amount(1000) }

    command = Bank::API::Commands::CheckBalance.new(origin_account: origin_customer.account)
    command.execute!

    expected_receipt = <<~RECEIPT
      Operation: Balance checking.
      Status: Transaction completed successfully

      Date: #{TestOutputHelpersModule.format_time(command.finished_at)}
      Source's account: '#{command.origin_account.id}' (#{command.origin_account.customer.email})
      Amount: R$ 10.0
      Execution time: #{TestOutputHelpersModule.format_execution_time(command.execution_time)}

      Bank 2018
    RECEIPT

    receipt = TestOutputHelpersModule.generate_receipt_for_command(command)

    # Remove all output characters that colorizes string
    expect(receipt.gsub(/(\e\[.{,2})/, '')).to eq(expected_receipt)
  end
end