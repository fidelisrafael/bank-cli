require_relative 'cli/commands'
require_relative 'cli/option_parser'
require_relative 'cli/output_helpers'

require 'json'

module Bank
  module CLI
    class TransactionNotValidatedError < Exception; end;
    class << self

      include CLI::OutputHelpers

      def start_from_argv(argv, wait_confirmation = false)
        # First the parse the data received from command line(`ARGV`)
        parser = CLI::OptionParser.new(argv)
        options = parser.parse!

        # First we print the summary of the transaction and waits
        # for user to confirm the action
        wait_user_confirmation(options) if wait_confirmation

        # With the formatted options, start the CLI
        CLI.start!(options)
      end

      def start!(options = {})
        command_name = options[:command_name]

        # Make sure this is a valid command
        validate_command!(command_name, options)

        # Setup the database
        Bank::DataStore.load!

        # Dispatch the command to the m
        command = run_command!(command_name, options)

        # Give feedback to user
        response_for_command(command)
      end

      # Check if the application is running in DEBUG mode.
      # This is useful for seeing the entirely and detailed Exception's backtrace
      def debug?
        ENV['DEBUG'] == 'true'
      end

      private

      def wait_user_confirmation(options)
        # Display one brief summary of the transaction so user
        # can review and approve it before proceding
        print_transaction_summary(options)

        # Wait user to reply the question
        wait_for_transaction_validation(options)

        # Just notify the user that the transaction is about to happen
        print_transaction_authorization_line(options)
      end


      def validate_command!(command_name, _options = {})
        API::Validator.validate_command!(command_name)
      end

      def response_for_command(command)
        if command.success?
          log "Yeah, your transaction is done!\n".colorize(:blue).bold.underline
          log generate_receipt_for_command(command)
        else
          log "Something went wrong with the operation \"#{command.command_name}\"\n".colorize(:red).bold.underline
          log generate_receipt_for_command(command)
        end
      end

      def run_command!(command_name, options = {})
        log_command(command_name, options) if  debug?

        CLI::Commands.public_send("run_#{command_name}_command!", options)
      end
    end
  end
end
