# frozen_string_literal: true

# Standard lib dependencies
require 'base64'
require 'fileutils'

module Bank
  # This module contains all helpers methods to deal with HTTP requests and
  # data handling(such saving, reading from cache, etc) and formatting output
  module Utils
    # The main root folder of application
    ROOT_DIR = File.expand_path('../..', File.dirname(__FILE__))

    # The directory where ALL data is saved
    DATA_DIRECTORY = File.join(ROOT_DIR, 'data')

    # Helper method wich executes the given `block` and returns the amount of seconds
    # of execution time. This method is usefull for benchmarks.
    #
    # Ex:
    # total_secs = with_execution_time do
    #  sleep(5)
    # end
    # puts total_secs # 5000
    def with_execution_time(&block)
      start_time = Time.now

      yield block if block_given?

      (Time.now - start_time)
    end

    def file_exists?(filename)
      File.exist?(File.join(DATA_DIRECTORY, filename))
    end

    def create_data_directory!
      FileUtils.mkdir_p(DATA_DIRECTORY)
    end

  end
end
