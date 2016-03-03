require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainReencrypt < Knife
      include Knife::KeychainBase
      
      option :current_key_file,
      :long  => "--current-key-file NAME",
      :description => "Current data bag secret key"

      option :new_key_file,
      :long  => "--new-key-file NAME",
      :description => "New data bag secret key"

      option :global,
      :long  => "--[no-]global",
      :boolean => true,
      :description => "Store as global key (default: false)",
      :default => false
      
      banner "knife keychain reencrypt NAME PATH (options)"
      
      def run
        # Initialize the keychain and keychain_keys data bags
        keychain_bag
        keychain_keys_bag

        store_environment = (config[:global] ? "_default" : environment)

        global_keychain_item = search(:keychain, "chef_environment:_default AND name:#{key_name}").first
        keychain_item = search(:keychain, "chef_environment:#{store_environment} AND name:#{key_name}").first

        keychain_key = read_key(keychain_item, [config[:current_key_file], config[:new_key_file]])
        store_key(keychain_item, keychain_key, config[:new_key_file])
        
        global_indicator = config[:global] ? " (as a global key)" : ""
        
        ui.info "Reencrypted attribute '#{key_name}' in the keychain#{global_indicator}!\n"
      end
    end
  end
end
