require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainStore < Knife
      include Knife::KeychainBase
      
      option :description,
      :long  => "--description DESCRIPTION",
      :description => "A description for the key you're storing (optional)"

      option :global,
      :long  => "--[no-]global",
      :boolean => true,
      :description => "Store as global key (default: false)",
      :default => false
      
      banner "knife keychain store NAME PATH (options)"
      
      def run
        # Initialize the keychain and keychain_keys data bags
        keychain_bag
        keychain_keys_bag

        raise "You must supply a name and source file for the key!" if !key_name || !key_file_path
        raise "No file found at: #{key_file_path}" if !File.exist?(key_file_path)

        store_environment = (config[:global] ? "_default" : environment)

        keychain_item = search(:keychain, "chef_environment:#{store_environment} AND name:#{key_name}").first || Chef::DataBagItem.new
        keychain_item.data_bag("keychain")
        keychain_item.raw_data = {
          "id" => "#{store_environment}---#{key_name}",
          "chef_environment" => store_environment,
          "name" => key_name,
          "group" => config[:group],
          "description" => config[:description]
        }
        keychain_item.save
        
        begin
          keychain_key = Chef::EncryptedDataBagItem.load(:keychain_keys, keychain_item.id).to_hash
        rescue Net::HTTPServerException => e
          if e.response.is_a?(Net::HTTPNotFound)
            ui.info "creating encrypted keychain_key for '#{key_name}'"
            keychain_key = {
              "id" => keychain_item.id
            }
          else
            raise e
          end
        end

        keychain_key["content"] = IO.read(key_file_path)
        
        encrypted_keychain_key = Chef::DataBagItem.from_hash(Chef::EncryptedDataBagItem.encrypt_data_bag_item(keychain_key, Chef::EncryptedDataBagItem.load_secret))
        encrypted_keychain_key.data_bag("keychain_keys")
        encrypted_keychain_key.save
        
        global_indicator = config[:global] ? " (as a global key)" : ""
        
        ui.info "Stored attribute '#{key_name}' in the keychain#{global_indicator}!\n"
      end
    end
  end
end
