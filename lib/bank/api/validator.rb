module Bank
  module API
    class InvalidCommandError < Exception; end
    class InvalidAccountNumberError < Exception; end
    class InvalidAmountError < Exception; end
    class SameAccountError < Exception; end

    module Validator
      # ALl the current commands that one user can perform
      VALID_COMMANDS = {
        transfer: 'transfer',
        check_balance: 'check_balance'
      }.freeze

      module_function

      def valid_command?(command_name)
        return VALID_COMMANDS.key?(command_name.to_s.intern)
      end

      def valid_account_id?(account_id)
        return false if empty_account_id?(account_id)

        return true
      end

      def empty_account_id?(account_id)
        return (account_id.nil? || account_id.strip.empty?)
      end

      def valid_minimum_amount?(amount)
        return amount.to_f >= MINIMUM_AMOUNT_TO_BE_HANDLED.to_f
      end

      def validate_accounts_id!(source_account, destination_account)
        if source_account.to_s === destination_account.to_s
          raise SameAccountError, "You cant perform this command between the same accounts"
        end

        true
      end

      def validate_command!(command_name)
        unless valid_command?(command_name)
          raise InvalidCommandError, "The command #{command_name} is not valid"
        end

        true
      end

      def validate_destination_account!(account_id)
        validate_account!(account_id, 'The destination account ID is not valid')
      end

      def validate_source_account!(account_id)
        validate_account!(account_id, 'The source account ID is not valid')
      end

      def validate_account!(account_id, message = 'This account is invalid')
        unless valid_account_id?(account_id)
          raise InvalidAccountNumberError, message
        end

        true
      end

      def validate_minimum_amount!(amount)
        unless valid_minimum_amount?(amount)
          raise InvalidAmountError, "The amount \"#{amount.to_f}\" is not valid for this command"
        end

        true
      end
    end
  end
end