require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainRemove < Knife
      include Knife::KeychainBase

      option :global,
      :long  => "--[no-]global",
      :boolean => true,
      :description => "Remove the global version of the key (default: false)",
      :default => false

      banner "knife keychain remove NAME (options)"

      def run
        store_environment = (config[:global] ? "_default" : environment)
        global_indicator = (config[:global] ? "GLOBAL " : "")

        key_id = nil
        keychain_items = search(:keychain, default_conditions(store_environment).join(" AND "))
        keychain_item_names = keychain_items.map { |keychain_item| keychain_item['name'] }.join("\n")
        
        confirm("\n#{keychain_item_names}\n\nDo you really want to delete the above #{global_indicator}keys from the keychain")

        keychain_items.each do |keychain_item|
          begin
            keychain_key = Chef::DataBagItem.load(:keychain_keys, keychain_item.id)
            destroy_item keychain_key
          rescue Net::HTTPServerException => e
            raise e if !e.response.is_a?(Net::HTTPNotFound)
          end
          destroy_item keychain_item
          ui.info "Removed #{global_indicator}'#{keychain_item["name"]}' from the keychain!"
        end
      end
      
      def destroy_item(data_bag_item)
        data_bag_item.chef_server_rest.delete_rest("data/#{data_bag_item.data_bag}/#{data_bag_item.id}")
      end
    end
  end
end
