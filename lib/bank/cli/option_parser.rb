# frozen_string_literal: true

require 'optparse'
require_relative '../api/validator'

module Bank
  module CLI
    class OptionParser
      attr_reader :args

      def initialize(args = [])
        @args = args
      end

      def parse!
        # Creates one `Hash` with the parsed options from the received args
        options = parse_options!(@args.dup)

        # Returns the object validate
        return options
      end

      private

      def parse_options!(args)
        options = {}

        parser = create_parser(options)
        parser.parse!(args) # populate `options`

        return options
      end

      def create_parser(options = {})
        # Make sure  to use the default `Ruby` OptionParser (since this class has the same name)
        ::OptionParser.new do |parser|
          parser.banner = 'Usage: bin/bank [command] [options]'
          parser.separator ''

          parser.on('--cNAME', '--command=COMMAND', 'Name of the command to run') do |command|
            options[:command_name] = command
          end

          parser.on('--oACCOUNT_ID', '--origin=ACCOUNT_ID', 'The source account ID') do |account_id|
            options[:origin_account_id] = account_id
          end

          parser.on('--dACCOUNT_ID', '--dest=ACCOUNT_ID', 'The destination account ID') do |account_id|
            options[:destination_account_id] = account_id
          end

          parser.on('--aAMOUNT', '--amount=AMOUNT', 'The total amount of money to be handled') do |amount|
            options[:amount] = amount.to_f
          end
        end
      end
    end
  end
end