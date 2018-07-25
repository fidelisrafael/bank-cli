# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bank::API::Commands::BaseCommand, type: :command do

  class MyValidCommand < Bank::API::Commands::BaseCommand
    def execute_command!
      true
    end
    def rollback!
    end
    def validate!
      true
    end
    def command_name
      'valid_command'
    end
  end

  class MyInvalidCommand < MyValidCommand
    def execute_command!
      false
    end

    def validate!
      false
    end
    def command_name
      'invalid_command'
    end
  end

  class MyInvalidExceptionCommand < MyInvalidCommand
    def validate!
      raise "Error"
    end
  end

  class CommandWithRollback < MyValidCommand
    attr_reader :some_value

    def initialize(*)
      @some_value = :initial
    end

    def execute_command!
      with_rollback do
        @some_value = :changed

        # Raising the error after changing some object
        raise "Some error"
      end
    end

    # This method is called when something goes wrong
    def rollback!
      @some_value = :initial
    end
  end

  before :each do
    @object = subject.class.new
  end

  it 'must initialize `@initialized_at` as a Time in initialize' do
    expect(@object.initialized_at).to be_a(Time)
  end

  it 'must raise a NotImplementedError error when calling `command_name`' do
    expect { @object.command_name }.to raise_error(NotImplementedError)
  end

  it 'must raise a NotImplementedError error when calling `validate!`' do
    expect { @object.validate! }.to raise_error(NotImplementedError)
  end

  it 'must raise a NotImplementedError error when calling `rollback!`' do
    expect { @object.rollback! }.to raise_error(NotImplementedError)
  end

  it 'must raise a NotImplementedError error when calling `execute!`' do
    expect { @object.execute! }.to raise_error(NotImplementedError)
  end

  it 'must raise a NotImplementedError error when calling `execute_command!`' do
    expect { @object.send(:execute_command!) }.to raise_error(NotImplementedError)
  end

  it 'must allow to check if action runned with success' do
    valid_command = MyValidCommand.new.execute!
    invalid_command = MyInvalidCommand.new.execute!

    expect(valid_command.success?).to be_truthy
    expect(invalid_command.success?).to be_falsey
  end

  it 'must allow to check if action runned with error' do
    valid_command = MyValidCommand.new.execute!
    invalid_command = CommandWithRollback.new.execute!

    expect(valid_command.error?).to be_falsey
    expect(invalid_command.error?).to be_truthy
  end

  it 'must allow to check if command was executed' do
    valid_command = MyValidCommand.new.execute!
    rollback_command = CommandWithRollback.new.execute!
    invalid_command = MyInvalidCommand.new.execute!
    exception_command =  MyInvalidExceptionCommand.new

    expect { exception_command.execute! }.to raise_error(RuntimeError)

    expect(valid_command.executed?).to be_truthy
    expect(invalid_command.executed?).to be_truthy
    expect(rollback_command.executed?).to be_truthy
    expect(exception_command.executed?).to be_falsey
  end

  it 'must register `@started_at` when executing one command' do
    valid_command = MyValidCommand.new

    expect(valid_command.started_at).to be_nil

    valid_command.execute!

    expect(valid_command.started_at).to be_a(Time)
  end

  it 'must register `@finished_at` when executing one command' do
    valid_command = MyValidCommand.new

    expect(valid_command.finished_at).to be_nil

    valid_command.execute!

    expect(valid_command.finished_at).to be_a(Time)
  end

  it 'must register `@execution_time` when executing one command' do
    valid_command = MyValidCommand.new

    expect(valid_command.execution_time).to be_nil

    valid_command.execute!

    expect(valid_command.execution_time).to be_a(Float)
  end

  it 'must allow to execute with rollback' do
    rollback_command = CommandWithRollback.new

    expect(rollback_command.some_value).to eq(:initial)

    rollback_command.execute! # This will raise an error

    expect(rollback_command.some_value).to eq(:initial)
    expect(rollback_command.error?).to be_truthy
  end

  it 'must raises one Exception when `validate!` throws one exception' do
    command = MyInvalidExceptionCommand.new

    expect {
      command.validate!
    }.to raise_error(RuntimeError)
  end

  it 'must not execute the command when `validate!` fails' do
    command = MyInvalidExceptionCommand.new

    expect {
      command.execute!
    }.to raise_error(RuntimeError)

    expect(command.success?).to be_falsey
    expect(command.executed?).to be_falsey
  end

  it 'must register the last Exception when running `with_rollback`' do
    rollback_command = CommandWithRollback.new.execute!

    expect(rollback_command.rollback_exception).to be_a(RuntimeError)
  end

  it 'must be considered an error when some exception raises within `with_rollback`' do
      rollback_command = CommandWithRollback.new.execute!

      expect(rollback_command.error?).to be_truthy
    end
end