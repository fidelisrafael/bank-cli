# frozen_string_literal: true

module Bank
  module CLI
    # This module contains helpers related to output in console, this includes
    # formatted and colorized feedback(success/error) messages
    module OutputTemplates

      TRANSACTION_AUTHORIZED_HEADER = "Ok. Transaction authorized"

      # All replies that are considered as a valid confirmation from the user
      VALID_CONFIRMATION_RREPLIES = %w(y yes s sim noisquevoa nqv)

      CONFIRMATION_HEADERS = <<~HEADER
        Do you want to execute this transaction? If "yes" just type: "yes", otherwise type "no"
      HEADER

      TRANSFER_TRANSACTION_SUMMARY_TEMPLATE = <<~SUMMARY
        Please, review your transaction.

        Operation: %{operation_name}.

        Date: %{date}
        Source's account: '%{origin_account_id}'
        Destination's account: '%{destination_account_id}'
        Amount: %{amount}
      SUMMARY

      CHECK_BALANCE_TRANSACTION_SUMMARY_TEMPLATE = <<~SUMMARY
        Please, review your transaction.

        Operation: %{operation_name}.

        Date: %{date}
        Source's account: '%{origin_account_id}'
      SUMMARY

      TRANSACTIONS_SUMMARY_TEMPLATES = {
        transfer: TRANSFER_TRANSACTION_SUMMARY_TEMPLATE,
        check_balance: CHECK_BALANCE_TRANSACTION_SUMMARY_TEMPLATE
      }

      # This is the sintax for "squiggly heredoc" added in Ruby 2.3
      # This works almost like the `#strip_heredoc` from "ActiveSupport"
      # TODO: Move this to configuration file
      TRANSFER_COMMAND_RECEIPT_TEMPLATE = <<~RECEIPT
        Operation: Money transfer between accounts.
        Status: %{status_line}

        Date: %{date}
        Source's account: '%{origin_account_id}' (%{origin_customer_email})
        Destination's account: '%{destination_account_id}' (%{destination_customer_email})
        Amount: %{amount}
        Transaction Identifier: %{identifier}
        Execution time: %{execution_time}

        Bank 2018
      RECEIPT

      # TODO: Move this to configuration file
      CHECK_BALANCE_COMMAND_RECEIPT_TEMPLATE = <<~RECEIPT
        Operation: Balance checking.
        Status: %{status_line}

        Date: %{date}
        Source's account: '%{origin_account_id}' (%{origin_customer_email})
        Amount: %{amount}
        Execution time: %{execution_time}

        Bank 2018
      RECEIPT

      OPERATION_HEADER_LABELS = {
        transfer: 'Transfer beetwen two accounts',
        check_balance: 'Balance checking'
      }

      SUCCESSFULLY_TRANSACION_LABEL = 'Transaction completed successfully'.freeze
      ERROR_TRANSACTION_LABEL = 'Transaction not completed successfully'.freeze
    end
  end
end
