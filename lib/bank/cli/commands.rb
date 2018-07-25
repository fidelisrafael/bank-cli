module Bank
  module CLI
    module Commands
      class << self
        def run_transfer_command!(options = {})
          command_options = options.values_at(:origin_account_id,
                                              :destination_account_id,
                                              :amount)

          API::Commands.transfer!(*command_options)
        end

        def run_check_balance_command!(options = {})
          command_options = options.values_at(:origin_account_id)

          API::Commands.check_balance!(*command_options)
        end
      end
    end
  end
end