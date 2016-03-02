require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainReencrypt < Knife
      include Knife::KeychainBase
      
      option :current_key_file,
      :long  => "--current-key-file",
      :description => "Current data bag secret key"

      option :new_key_file,
      :long  => "--new-key-file",
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

        raise "You must supply a name and source file for the key!" if !key_name || !key_file_path
        raise "No file found at: #{key_file_path}" if !File.exist?(key_file_path)

        store_environment = (config[:global] ? "_default" : environment)

        global_keychain_item = search(:keychain, "chef_environment:_default AND name:#{key_name}").first
        keychain_item = search(:keychain, "chef_environment:#{store_environment} AND name:#{key_name}").first
        
        begin
          keychain_key = Chef::EncryptedDataBagItem.load(:keychain_keys, keychain_item.id, Chef::EncryptedDataBagItem.load_secret(config[:current_key_file])).to_hash
        rescue Net::HTTPServerException => e
          if e.response.is_a?(Net::HTTPNotFound)
            ui.info "'#{key_name}' doesn't exist"
            exit
          else
            raise e
          end
        end

        keychain_key["content"] = IO.read(key_file_path)
        
        encrypted_keychain_key = Chef::DataBagItem.from_hash(Chef::EncryptedDataBagItem.encrypt_data_bag_item(keychain_key, Chef::EncryptedDataBagItem.load_secret(config[:new_key_file])))
        encrypted_keychain_key.data_bag("keychain_keys")
        encrypted_keychain_key.save
        
        global_indicator = config[:global] ? " (as a global key)" : ""
        
        ui.info "Reencrypted attribute '#{key_name}' in the keychain#{global_indicator}!\n"
      end
    end
  end
end
