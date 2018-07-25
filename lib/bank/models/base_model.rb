require 'securerandom'

module Bank
  module Models
    class BaseModel
      # The length of the ID string to be generated using `SecureRandom`.
      # @note: `SecureRandom.hex` will generate the string with **twice** the length.
      ID_ATTRIBUTE_LENGTH = 4

      attr_reader :id

      def initialize(*)
        generate_unique_id

        self
      end

      def dataset_name
        raise 'Must be explicitly declared in subclasses'
      end

      def update(&block)
        Bank::DataStore.update_record(self, &block)
      end

      def ==(other_model)
        self.class == other_model.class && self.id == other_model.id
      end

      private

      def generate_unique_id
        loop do
          @id = SecureRandom.hex(ID_ATTRIBUTE_LENGTH / 2)

          break unless id_exists_in_database?(@id)
        end

        @id
      end

      def id_exists_in_database?(id)
        record = DataStore.find_in_dataset(dataset_name, 'id', id)

        !record.nil? && !record.id.nil?
      end
    end
  end
end