require_relative 'base_command'

module Bank
  module API
    class Commands::CheckBalance < Commands::BaseCommand
      attr_reader :origin_account, :amount

      def initialize(origin_account:)
        super()
        @origin_account = origin_account
      end

      def command_name
        'check_balance'
      end

      def validate!
        validate_source_account!
      end

      private

      def execute_command!
        # Nothing much to do
        @amount = @origin_account.amount

        true
      end

      def validate_source_account!
        Validator.validate_source_account!(@origin_account&.id)
      end
    end
  end
end