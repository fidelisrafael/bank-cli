# frozen_string_literal: true

require_relative 'output_templates'

module Bank
  module CLI
    # This module contains helpers related to output in console, this includes
    # formatted and colorized feedback(success/error) messages
    module OutputHelpers
      # All the CONSTANTS(such `TRANSACTIONS_SUMMARY_TEMPLATES` cames from this module)
      include OutputTemplates

      def print_transaction_summary(options)
        puts generate_transaction_summary(options)
      end

      def generate_transaction_summary(options, time = Time.now)
        command_name = options[:command_name].to_sym
        template = TRANSACTIONS_SUMMARY_TEMPLATES[command_name]
        placeholders = options.merge(date: format_time(time),
                                     amount: format_value(options[:amount]),
                                     operation_name: OPERATION_HEADER_LABELS[command_name])

        return (template % placeholders)
      end

      def print_transaction_authorization_line(options)
        puts "\n#{TRANSACTION_AUTHORIZED_HEADER.underline.bold}\n\n"
      end

      def confirmation_reply?(reply)
        VALID_CONFIRMATION_RREPLIES.member?(reply)
      end

      def wait_for_transaction_validation(options, device = $stdin)
        puts "\n#{CONFIRMATION_HEADERS.underline.bold}"
        print "=>> "

        reply = device.gets.chomp

        unless confirmation_reply?(reply.downcase)
          raise TransactionNotValidatedError, 'This transaction was aborted'
        end
      end

      def generate_receipt_for_command(command)
        # Basic placeholders that can be used in any response
        common_placeholders = {
          date: format_time(command.finished_at),
          origin_account_id: command.origin_account.id,
          origin_customer_email: command.origin_account.customer.email,
          status_line: status_line_for_command(command),
          execution_time: format_execution_time(command.execution_time)
        }

        if command.command_name == 'transfer'
          output_template = TRANSFER_COMMAND_RECEIPT_TEMPLATE

          custom_placeholders = {
            destination_account_id: command.destination_account.id,
            destination_customer_email: command.destination_account.customer.email,
            amount: format_value(command.amount),
            identifier: command.transaction_identifier,
          }

        elsif command.command_name == 'check_balance'
          output_template = CHECK_BALANCE_COMMAND_RECEIPT_TEMPLATE

          custom_placeholders = {
            amount: format_value(command.amount)
          }
        end

        # Merge all custom and basic placeholders
        placeholders = common_placeholders.merge(custom_placeholders)

        # Substitute placeholders in message
        (output_template % placeholders)
      end

      def status_line_for_command(command)
        line = command.success? ? SUCCESSFULLY_TRANSACION_LABEL : ERROR_TRANSACTION_LABEL

        line.underline
      end

      def format_time(time)
        time.to_datetime.strftime('%d/%m/%Y %T')
      end

      def format_execution_time(time)
        "#{"%.2f" % time} ms"
      end

      def format_value(value)
        "R$ #{(value.to_f / API::ONE_REAL_IN_CENTS).round(4)}"
      end

      def log(message)
        puts message
      end

      def log_command(command_name, options = {})
        log "Running: `#{command_name.colorize(:green)}` with options: #{JSON.pretty_generate(options)}" if debug?
      end

      def error(message, force = false)
        return nil if !log_errors? && !force

        log "[ERROR] #{message}".bold.colorize(:red)
      end

      def verbose?
        true # just to allow configuration for now
      end

      def silent?
        !verbose?
      end
    end
  end
end
