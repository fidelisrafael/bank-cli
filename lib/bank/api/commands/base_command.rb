require_relative '../../utils'
module Bank
  module API
    class Commands::BaseCommand
      class InvalidDataError < Exception; end

      attr_reader :initialized_at, :started_at, :finished_at, :execution_time,
                  :rollback_exception

      include Utils

      def initialize(*)
        @initialized_at = Time.now
      end

      def execute!
        # Dont allow to execute the same command twice
        return if executed?

        @started_at = Time.now

        @execution_time = with_execution_time do
          validate!
          @success = true if execute_command!
        end

        @finished_at = Time.now

        self
      end

      def success?
        return false if error?

        @success == true
      end

      def error?
        @error_ocurried == true
      end

      def executed?
        !@finished_at.nil?
      end

      def command_name
        raise NotImplementedError, 'Must be implemented in subclass'
      end

      def validate!
        raise NotImplementedError, 'Must be implemented in subclass'
      end

      def rollback!
        raise NotImplementedError, 'Must be implemented in subclass'
      end

      private

      def with_rollback(&block)
        begin
          block.call
        rescue Exception => e
          # The ensure the system that one error REALLY happened
          @error_ocurried = true
          # Saves the exception ocurried here internally to be raised
          # outsided if needed
          @rollback_exception = e

          # Start the rollback process
          rollback!
        end
      end

      def execute_command!
        raise NotImplementedError, 'Must be implemented in subclass'
      end
    end
  end
end