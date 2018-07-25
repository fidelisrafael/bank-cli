require_relative 'utils'

require_relative 'api/commands'
require_relative 'api/validator'

module Bank
  module API
    # This constant determine the minimum amount of money that will be
    # allowed to handle in the application.
    MINIMUM_AMOUNT_TO_BE_HANDLED = 0.1.freeze

    # The minimum amount of money in this currency
    ONE_CENT = 1.0

    # The "base" amount of money in this currency
    ONE_REAL_IN_CENTS = (ONE_CENT * 100) # 100 cents
  end
end