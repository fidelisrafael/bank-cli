require_relative 'base_model'

module Bank
  module Models
    class Account < BaseModel

      DATASET_NAME = 'accounts'.freeze

      attr_reader :amount, :customer_id

      def initialize(amount:, customer_id:)
        @amount, @customer_id = amount, customer_id

        super()
      end

      def update_amount(amount)
        @amount = amount.to_f
      end

      def customer
        return nil if @customer_id.nil? || @customer_id.empty?

        @customer ||= DataStore.find_in_dataset(customers_dataset_name, 'id', @customer_id)
      end

      def customers_dataset_name
        DataStore::CUSTOMERS_DATASET
      end

      def dataset_name
        DATASET_NAME
      end
    end
  end
end