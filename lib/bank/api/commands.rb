require 'securerandom'
require 'bigdecimal'

module Bank
  module API
    module Commands

      class << self
        def create_customer!(customer_data = {})
          existent_customer = find_customer_by_email(customer_data[:email])

          return existent_customer if existent_customer

          command = execute_command!(Commands::CreateCustomer.new(customer_data))

          return command.customer
        end

        def transfer!(origin_account_id, destination_account_id, amount)
          origin_account = find_in_accounts_dataset('id', origin_account_id)
          destination_account = find_in_accounts_dataset('id', destination_account_id)

          command = Commands::Transfer.new(origin_account: origin_account,
                                           destination_account: destination_account,
                                           amount: amount.to_f)
          execute_command!(command)
        end

        def check_balance!(origin_account_id)
          origin_account = find_in_accounts_dataset('id', origin_account_id)
          command = Commands::CheckBalance.new(origin_account: origin_account)

          execute_command!(command)
        end

        private

        def execute_command!(command_object)
          command_object.execute!

          return command_object
        end

        def find_customer_by_email(email)
          find_in_customers_dataset('email', email.downcase) { |attribute| attribute.downcase }
        end

        def find_in_customers_dataset(attribute, value)
          DataStore.find_in_dataset(DataStore::CUSTOMERS_DATASET, attribute, value)
        end

        def find_in_accounts_dataset(attribute, value)
          DataStore.find_in_dataset(DataStore::ACCOUNTS_DATASET, attribute, value)
        end
      end
    end
  end
end

require_relative 'commands/transfer'
require_relative 'commands/check_balance'
require_relative 'commands/create_customer'