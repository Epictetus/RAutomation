module RAutomation
  module Adapter
    module Autoit
      class Window
        include WaitHelper
        include Locators

        class << self
          # @private
          def autoit
            @@autoit
          end

          # @private
          def load_autoit
            @@autoit = WIN32OLE.new('AutoItX3.Control')
          rescue WIN32OLERuntimeError
            dll = File.dirname(__FILE__) + "/../../../../ext/AutoItX/AutoItX3.dll"
            system("regsvr32.exe /s #{dll.gsub('/', '\\')}")
            @@autoit = WIN32OLE.new('AutoItX3.Control')
          end
        end

        load_autoit
        @@autoit.AutoItSetOption("WinWaitDelay", 350)

        # Locators of the window.
        attr_reader :locators

        # @private
        # Special-cased locators
        LOCATORS = {
                [:title, Regexp] => :regexptitle,
                :index => :instance,
                :hwnd => :handle
        }

        # Creates the window object.
        # @note this method is not meant to be accessed directly, but only through {RAutomation::Window#initialize}!
        # @param [Hash] locators for searching the window.
        # @option locators [String, Regexp] :title Title of the window
        # @option locators [String, Regexp] :text Visible text of the window
        # @option locators [String, Regexp] :class Internal class name of the window
        # @option locators [String, Fixnum] :hwnd Window handle in decimal format
        # @option locators [String, Fixnum] :index 0-based index to specify n-th window if all other criteria match
        # @see RAutomation::Window#initialize
        def initialize(locators)
          @hwnd = locators[:hwnd]
          @locator_text = locators.delete(:text)
          extract(locators)
        end

        # Retrieves handle of the window.
        # @note Searches only for visible windows with having some text at all.
        # @see RAutomation::Window#hwnd
        def hwnd
          @hwnd ||= @@autoit.WinList(@locators, @locator_text).pop.compact.
                  find {|handle| w = self.class.new(:hwnd => handle.hex); w.visible? && !w.text.empty?}.
                  hex rescue nil
        end

        # @see RAutomation::Window#pid
        def pid
          @@autoit.WinGetProcess(hwnd)
        end

        # @see RAutomation::Window#title
        def title
          @@autoit.WinGetTitle(locator_hwnd)
        end

        # @see RAutomation::Window#activate
        def activate
          @@autoit.WinWait(locator_hwnd, "", 1)
          @@autoit.WinActivate(locator_hwnd)
          sleep 1
        end

        # @see RAutomation::Window#active?
        def active?
          @@autoit.WinActive(locator_hwnd) == 1
        end

        # @see RAutomation::Window#text
        def text
          @@autoit.WinGetText(locator_hwnd)
        end

        # @see RAutomation::Window#exists?
        def exists?
          @@autoit.WinExists(locator_hwnd) == 1
        end

        # @see RAutomation::Window#visible?
        def visible?
          @@autoit.WinGetState(locator_hwnd) & 2 == 2
        end

        # @see RAutomation::Window#maximize
        def maximize
          @@autoit.WinSetState(locator_hwnd, "", @@autoit.SW_MAXIMIZE)
          sleep 1
        end

        # @see RAutomation::Window#minimize
        def minimize
          @@autoit.WinSetState(locator_hwnd, "", @@autoit.SW_MINIMIZE)
          sleep 1
        end

        # @see RAutomation::Window#minimized?
        def minimized?
          @@autoit.WinGetState(locator_hwnd) & 16 == 16
        end

        # @see RAutomation::Window#restore
        def restore
          @@autoit.WinSetState(locator_hwnd, "", @@autoit.SW_RESTORE)
          sleep 1
        end

        # Activates the window and sends keys to it.
        #
        # Refer to AutoIt documentation at http://www.autoitscript.com/autoit3/docs/appendix/SendKeys.htm
        # for keys syntax.
        # @see RAutomation::Window#send_keys
        def send_keys(keys)
          wait_until do
            activate
            active?
          end
          @@autoit.Send(keys)
        end

        # @see RAutomation::Window#close
        def close
          @@autoit.WinClose(locator_hwnd)
          @@autoit.WinKill(locator_hwnd)
        end

        # @see Button#initialize
        # @see RAutomation::Window#button
        def button(locator)
          Button.new(self, locator)
        end

        # @see TextField#initialize
        # @see RAutomation::Window#text_field
        def text_field(locator)
          TextField.new(self, locator)
        end

        # Redirects all method calls not part of the public API to the AutoIt directly.
        # @example execute AutoIt's WinGetTitle function:
        #   RAutomation::Window.new(:hwnd => 123456).WinGetTitle(...)
        # @see RAutomation::Window#method_missing
        def method_missing(name, *args)
          @@autoit.send(name, *args)
        end

        # @private
        def locator_hwnd
          "[HANDLE:#{hwnd.to_i.to_s(16)}]"
        end
      end
    end
  end
end