# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bank::DataStore, type: :lib do
  before :each do
    subject.reset! if subject.loaded?
  end

  DB_NAMES = Bank::DataStore::DATABASE_FILENAMES # shortcut

  it 'must allow to load the database' do
    expect(subject.load!).to eq(subject.db)
    expect(subject).to be_loaded
  end

  it 'must allow to unload the database after loading it' do
    expect(subject.load!).to eq(subject.db)
    expect { subject.unload! }.not_to raise_error
    expect(subject.db).to be_nil
  end

  it 'must raise an DataStoreNotLoaded when trying to unload one database beforing loading it' do
    expect {
      subject.unload!
    }.to raise_error(Bank::DataStore::DataStoreNotLoaded)
  end

  it 'must allow to access the database object' do
    expect(subject.db).to be_nil
    expect(subject.load!).not_to be_nil
    expect(subject.db).not_to be_nil
  end

  it 'must allow to check if database is loaded' do
    expect(subject.loaded?).to be_falsey
    expect(subject.load!)
    expect(subject.loaded?).to be_truthy
  end

  it 'should creates one single reference to the database' do
    subject.load!

    last_db = subject.db
    expect(subject).to be_loaded

    subject.load! # try to load again

    expect(subject.db.__id__).to eq(last_db.__id__)
  end

  it 'should allow to open one transaction in database after loading' do
    subject.load!

    subject.transaction do |database|
      expect(database).not_to be_nil
    end
  end

  it 'must allow to add records to a dataset' do
    subject.load!
    new_dataset = SecureRandom.hex(5)

    expect {
      subject.transaction {|db| expect(db[new_dataset]).to be_nil }
    }

    subject.append_in_dataset(new_dataset, { some: :data })

    expect {
      subject.transaction do |db|
        expect(db[new_dataset]).not_to be_empty
        expect(db[new_dataset][:some]).to be(:data)
      end
    }
  end

  it 'must allow to find one specific record inside the store' do
    subject.load!

    customer = OpenStruct.new(name: 'Rafael Fidelis', email: 'rafa_fidelis@yahoo.com.br')
    subject.append_in_dataset('customers', customer)

    found_object = subject.find_in_dataset('customers', :name, 'Rafael Fidelis')
    not_found_object = subject.find_in_dataset('customers', :name, 'Another name')

    expect(found_object).to eq(customer)
    expect(not_found_object).to be_nil
  end

  it 'most allow to reset! the database and delete the file' do
    subject.load!
    subject.transaction {} # just to create the file

    expect(File.exists?(subject.send(:full_path_to_database_file))).to be_truthy
    expect(subject.loaded?).to be_truthy

    subject.reset! # clear

    expect(File.exists?(subject.send(:full_path_to_database_file))).to be_falsey
    expect(subject.loaded?).to be_falsey
  end

  it 'should NOT allow to execute transactions in database if not loaded' do
    expect {
      subject.transaction {|db| db }
    }.to raise_error(Bank::DataStore::DataStoreNotLoaded)
  end

  it 'must allow to update one record in the dataset' do
    subject.load!

    customer = OpenStruct.new(name: 'Rafael Fidelis', email: 'rafa_fidelis@yahoo.com.br', dataset_name: 'customers')
    subject.append_in_dataset('customers', customer)

    subject.update_record(customer) do |record|
      expect(record.name).to eq('Rafael Fidelis')
      # Changing the name
      record.name = 'New Name'
    end

    # Closes and open the database again to make sure we are getting
    # the most recent data from the file
    subject.reload!

    record = subject.find_in_dataset('customers', :name, 'New Name')

    # Makes sure the object and the content in the database are updated
    expect(record.name).to eq('New Name')
    expect(customer.name).to eq('New Name')
  end

  it 'must load the PStore adapter' do
    store = subject.send(:load_store!, :pstore)

    expect(store).to be_a(PStore)
  end

  it 'must load the YAML::Store adapter' do
    store = subject.send(:load_store!, :yaml)

    expect(store).to be_a(Psych::Store)
  end

  it 'must raise an error when trying to load invalid adapter' do
    expect {
      subject.send(:load_store!, :inexistent)
    }.to raise_error(RuntimeError)
  end

  it 'must properly replace records in one collection' do
    collection = [ { name: 'Rafael', email: 'r@r.com' },  { name: 'Another one', email: 'ok@ok.com' } ]

    new_record = { name: 'Rafael Fidelis', email: 'r2@r.com' }

    subject.send(:replace_records_in_collection, collection, collection[0], new_record)

    expect(collection).to eq([ { name: 'Rafael Fidelis', email: 'r2@r.com' },  { name: 'Another one', email: 'ok@ok.com' } ])
  end

  it 'The database filename must depends of the current environment' do
    last_env = ENV['APP_ENVIRONMENT']

    expect(subject.database_filename).to eq(DB_NAMES[subject.adapter] % { enviroment: last_env })

    ENV['APP_ENVIRONMENT'] = 'testing'

    expect(subject.database_filename).to eq(DB_NAMES[subject.adapter] % { enviroment: 'testing' })

    ENV['APP_ENVIRONMENT'] = last_env # reset it
  end

  it 'should allow to check the current adapter' do
    expect(subject.adapter).to eq(Bank::DataStore::CURRENT_DATABASE_ADAPTER)
  end

  it 'should allow to check the current database name' do
    expect(subject.database_filename).to eq(DB_NAMES[subject.adapter] % { enviroment: subject.current_enviroment })
  end
end