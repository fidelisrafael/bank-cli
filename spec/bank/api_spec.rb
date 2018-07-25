# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bank::API, type: :lib do

  it 'must declare the constant ONE_CENT' do
    expect(subject.constants).to include(:ONE_CENT)
  end

  it 'must declare the constant ONE_REAL_IN_CENTS' do
    expect(subject.constants).to include(:ONE_REAL_IN_CENTS)
  end

  it 'must declare the constant MINIMUM_AMOUNT_TO_BE_HANDLED' do
    expect(subject.constants).to include(:MINIMUM_AMOUNT_TO_BE_HANDLED)
  end

  it 'must declares ONE_CENT constant with value 1.0' do
    expect(subject::ONE_CENT).to eq(1.0)
  end

  it 'must declares MINIMUM_AMOUNT_TO_BE_HANDLED constant with value 0.1' do
    expect(subject::MINIMUM_AMOUNT_TO_BE_HANDLED).to eq(0.1)
  end

  it 'must declares ONE_REAL_IN_CENTS constant with value 1 hundred times ONE_CENT' do
    expect(subject::ONE_REAL_IN_CENTS).to eq(subject::ONE_CENT * 100)
  end
end