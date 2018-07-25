require_relative 'base_model'

module Bank
  module Models
    class Customer < BaseModel

      DATASET_NAME = 'customers'.freeze
      CUSTOMER_RELANTIONSHIOP_FKEY = 'customer_id'.freeze

      attr_reader :name, :email

      def initialize(name:, email:)
        @name, @email = name, email

        super()
      end

      def account
        return nil if @id.nil? || @id.empty?

        @account ||= DataStore.find_in_dataset(accounts_dataset_name, CUSTOMER_RELANTIONSHIOP_FKEY, @id)
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