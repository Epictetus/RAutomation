module RAutomation
  module Adapter
    module Ffi
      # @private
      module Locators

        private

        def extract(locators)
          # windows locators
          @hwnd = locators[:hwnd].to_i if locators[:hwnd]
          locators[:pid] = locators[:pid].to_i if locators[:pid]
          locators[:index] = locators[:index].to_i if locators[:index]

          # control locator
          locators[:id] = locators[:id].to_i if locators[:id]
          @locators = locators
        end
      end
    end
  end
end