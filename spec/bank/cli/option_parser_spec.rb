# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/bank/cli'

RSpec.describe Bank::CLI::OptionParser, type: :cli do
  OPTIONS_FOR_TRANSFER = [
    %w[--command=transfer --origin=e625 --dest=4d73 --amount=1],
    %w[--command transfer --origin e625 --dest 4d73 --amount 1],
    %w[--command=transfer --origin e625 --dest 4d73 --amount=1], # mixed
    %w[-ctransfer -oe625 -d4d73 -a1],
    %w[-c transfer -o e625 -d 4d73 -a 1],
  ]

  OPTIONS_FOR_CHECK_BALLANCE = [
    %w[--command=check_balance --origin=e625],
    %w[--command check_balance --origin e625],
    %w[--command check_balance --origin=e625] # mixed
  ]

  OPTIONS_FOR_TRANSFER.each do |argv_options|
    it 'should parse options for transfer properly' do
      parser = Bank::CLI::OptionParser.new(argv_options)
      parsed_options = parser.parse!

      expect(parsed_options).to eq(:command_name=>"transfer", :origin_account_id=>"e625", :destination_account_id=>"4d73", :amount=>1.0)
    end
  end

  OPTIONS_FOR_CHECK_BALLANCE.each do |argv_options|
    it 'should parse options for check_balance properly' do
      parser = Bank::CLI::OptionParser.new(argv_options)
      parsed_options = parser.parse!

      expect(parsed_options).to eq(:command_name=>"check_balance", :origin_account_id=>"e625")
    end
  end
end