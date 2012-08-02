require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainStore < Knife
      include Knife::KeychainBase
      
      banner "knife keychain initialize (options)"
      
      def run
        # Initialize the keychain and keychain_keys data bags
        keychain_bag
        keychain_keys_bag
      end
    end
  end
end