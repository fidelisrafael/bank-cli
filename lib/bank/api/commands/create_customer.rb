require_relative 'base_command'

module Bank
  module API
    class Commands::CreateCustomer < Commands::BaseCommand
      attr_reader :customer_data, :customer

      # Simple as a possible
      EMAIL_REGEXP = (/(.+)@(.+)\.(.+)/).freeze

      def initialize(customer_data = {})
        super()
        @customer_data = customer_data
      end

      def command_name
        'create_customer'
      end

      def validate!
        validate_user_name!
        validate_user_email!
      end

      private

      def create_account_object(account_data = {})
        Models::Account.new(account_data)
      end

      def create_customer_object(customer_data = {})
        Models::Customer.new(customer_data)
      end

      def create_customer_in_db(customer_data = {})
        customer = create_customer_object(customer_data)
        account = create_account_object(amount: 0, customer_id: customer.id)

        # First creates the customer in database (inside one transaction)
        DataStore.append_in_dataset(DataStore::CUSTOMERS_DATASET, customer)

        # And after creates the account for this customer in database
        DataStore.append_in_dataset(DataStore::ACCOUNTS_DATASET, account)

        return customer
      end

      def validate_user_name!
        raise InvalidDataError, 'Invalid name' if empty_value?(@customer_data[:name])

        return true
      end

      def validate_user_email!
        raise InvalidDataError, 'Invalid email' unless valid_email?(@customer_data[:email])

        return true
      end

      def valid_email?(email)
        return false if empty_value?(email)

        email.match?(EMAIL_REGEXP)
      end

      def empty_value?(value)
        value.nil? || value.empty?
      end

      def execute_command!
        @customer = create_customer_in_db(@customer_data)
      end

      def validate_source_account!
        Validator.validate_source_account!(@origin_account&.id)
      end
    end
  end
end