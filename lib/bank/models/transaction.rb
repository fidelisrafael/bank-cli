require_relative 'base_model'

module Bank
  module Models
    class Transaction < BaseModel

      DATASET_NAME = 'transactions'.freeze
      ACCOUNT_RELATIONSHIP_FKEY = 'account_id'.freeze

      VALID_TRANSACTIONS_TYPE = [:debit, :credit]

      attr_reader :account_id,
                  :destination_account_id,
                  :amount,
                  :datetime,
                  :description

      def initialize(account_id:, destination_account_id:, amount:, description: '')
        @account_id = account_id
        @destination_account_id = destination_account_id
        @amount = amount
        @description = description

        super()
      end

      def account
        return nil if @account_id.nil? || @account_id.empty?

        @customer ||= DataStore.find_in_dataset(accounts_dataset_name, ACCOUNT_RELATIONSHIP_FKEY, @account_id)
      end

      def customer
        account&.customer
      end

      def accounts_dataset_name
        DataStore::ACCOUNTS_DATASET
      end

      def dataset_name
        DATASET_NAME
      end
    end
  end
end