require_relative 'base_command'

module Bank
  module API
    class Commands::Transfer < Commands::BaseCommand
      attr_reader :origin_account, :destination_account, :amount

      def initialize(origin_account:, destination_account:, amount:)
        super()
        @origin_account = origin_account
        @destination_account = destination_account
        @amount = amount
      end

      def command_name
        'transfer'
      end

      def transaction_identifier
        @identifier ||= SecureRandom.hex(16)
      end

      def rollback!
        rollback_debit!
        rollback_credit!
      end

      def rollback_debit?
        return (error? && @debit_created == true)
      end

      def rollback_credit?
        return (error? && @credit_created == true)
      end

      private

      def validate!
        validate_source_account!
        validate_destination_account!
        validate_amount!
      end

      def execute_command!
        with_rollback do
          # First removes the money from the source account ("debit")
          create_debit_in_origin_account!

          # And last but not least creates the "credit" in source account
          create_credit_in_destination_account!
        end
      end

      def normalize_amount(amount)
        BigDecimal.new(amount.to_s)
      end

      def subtract_values(first_value, last_value)
        normalize_amount(first_value) - normalize_amount(last_value)
      end

      def add_values(first_value, last_value)
        normalize_amount(first_value) + normalize_amount(last_value)
      end

      def create_debit_in_account!(target_account, amount_to_debit)
        target_account.update do |account, _dataset|
          new_value = subtract_values(target_account.amount, amount_to_debit)
          target_account.update_amount(new_value)
        end
      end

      def create_credit_in_account!(target_account, amount_to_credit)
        target_account.update do |account, _dataset|
          new_value = add_values(target_account.amount, amount_to_credit)
          target_account.update_amount(new_value)
        end
      end

      def validate_source_account!
        Validator.validate_source_account!(@origin_account&.id)
        Validator.validate_accounts_id!(@origin_account&.id, @destination_account&.id)
      end

      def validate_destination_account!
        Validator.validate_destination_account!(@destination_account&.id)
      end

      def validate_amount!
        Validator.validate_minimum_amount!(@amount)
        validate_destination_account_amount!

        true
      end

      def validate_destination_account_amount!
        # if the source account does not have this value in balance
        # we do not authorize the transaction to happens
        if normalize_amount(@amount) > normalize_amount(@origin_account.amount)
          raise API::InvalidAmountError, "There's no enough money in account for this transaction"
        end

        true
      end

      ## Rollback strategies

      def rollback_debit!
        # If theres no need to rollback the "debit" transaction, returns
        return unless rollback_debit?
        # Don't do rollback twice
        return if @debit_rollbacked

        # One debit was created, so let's create one credit now
        create_credit_in_account!(@origin_account, @amount)

        # To notify the system
        @debit_rollbacked = true
      end

      def rollback_credit!
        # If theres no need to rollback the "credit" transaction, returns
        return unless rollback_credit?

        # Don't do rollback twice
        return if @credit_rollbacked

        # One "credit" was created, so let's create one "debit" now
        create_debit_in_account!(@destination_account, @amount)

        # To notify the system
        @credit_rollbacked = true
      end

      protected

      def create_debit_in_origin_account!
        create_debit_in_account!(@origin_account, @amount)
        @debit_created = true
      end

      def create_credit_in_destination_account!
        create_credit_in_account!(@destination_account, @amount)
        @credit_created = true
      end
    end
  end
end