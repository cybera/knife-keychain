require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainList < Knife
      include Knife::KeychainBase
      
      banner "knife keychain list (options)"
      
      def run
        search(:keychain, default_conditions.join(" AND ")).each do |keychain_item|
          extra = keychain_item['description'] ? ": #{keychain_item['description']}" : ""
          output(format_for_display(keychain_item['name'] + extra))
        end
      end
    end
  end
end
