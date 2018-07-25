require_relative 'utils'

module Bank
  module DataStore
    class DataStoreNotLoaded < RuntimeError; end;

    extend Utils

    # Base database filesnames
    DATABASE_FILENAMES = {
      pstore: 'db_%{enviroment}.pstore',
      yaml: 'db_%{enviroment}.yaml'
    }.freeze

    # The current implementation of filesystem storage
    # The possible values are: `:pstore` or `:yaml` (as a Symbol)
    # The application will use `DATABASE_FILENAMES` constant to determine the
    # name of the file to create in the file system.
    CURRENT_DATABASE_ADAPTER = :yaml

    # The "dataset" name to save "customers" records
    CUSTOMERS_DATASET = 'customers'.freeze

    # The "dataset" name to save "accounts" records
    ACCOUNTS_DATASET = 'accounts'.freeze

    @store = nil

    class << self
      def db
        @store
      end

      def unload!
        raise DataStoreNotLoaded unless loaded?

        @store = nil
      end

      def load!
        return @store if loaded?

        create_data_directory!

        @store = load_store!(adapter)
      end

      def loaded?
        !@store.nil?
      end

      def transaction(&block)
        raise DataStoreNotLoaded unless loaded?

        @store.transaction(&block)
      end

      def update_record(record, &block)
        transaction do |db|
          last_record = record.dup

          yield(record) if block_given?

          replace_records_in_collection(db[record.dataset_name], last_record, record)

          db.commit
        end
      end

      def append_in_dataset(dataset_name, data)
        transaction do |dataset|
          dataset[dataset_name] ||= []
          dataset[dataset_name] << data

          dataset.commit
        end
      end

      def find_in_dataset(dataset_name, attribute, value)
        transaction do |database|
          (database[dataset_name] || []).find do |record|
            attribute_value = record.public_send(attribute)
            attribute_value = block_given? ? yield(attribute_value) : attribute_value

            attribute_value == value
          end
        end
      end

      def reset!
        unload!
        delete_database_file!
      end

      def reload!
        unload!
        load!
      end

      def adapter
        CURRENT_DATABASE_ADAPTER
      end

      def database_filename
        DATABASE_FILENAMES[adapter] % { enviroment: current_enviroment }
      end

      def current_enviroment
        ENV['APP_ENVIRONMENT'] || 'development'
      end

      protected

      def load_store!(adapter)
        if adapter == :pstore
          load_pstore!
        elsif adapter == :yaml
          load_yaml_store!
        else
          raise "Database Adapter not set, check CURRENT_DATABASE_ADAPTER"
        end
      end

      def load_pstore!
        require 'pstore'

        PStore.new(full_path_to_database_file, true)
      end

      def load_yaml_store!
        require 'yaml/store'

        YAML::Store.new(full_path_to_database_file)
      end

      def full_path_to_database_file
        File.join(Utils::DATA_DIRECTORY, database_filename)
      end

      def delete_database_file!
        File.delete(full_path_to_database_file) if File.exists?(full_path_to_database_file)
      end

      def replace_records_in_collection(collection, old_record, new_record)
        last_index = collection.index {|record| record == old_record }

        return collection unless last_index # nothing found

        collection.delete_at(last_index)
        collection.insert(last_index, new_record)

        collection
      end
    end
  end
end