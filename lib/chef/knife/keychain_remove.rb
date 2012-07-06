require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainRemove < Knife
      include Knife::KeychainBase

      banner "knife keychain remove NAME (options)"
      
      def run
        key_id = nil
        keychain_items = search(:keychain, default_conditions.join(" AND "))
        keychain_item_names = keychain_items.map { |keychain_item| keychain_item['name'] }.join("\n")
        
        confirm("\n#{keychain_item_names}\n\nDo you really want to delete the above keys from the keychain?")

        keychain_items.each do |keychain_item|
          begin
            keychain_key = Chef::DataBagItem.load(:keychain_keys, keychain_item.id)
            destroy_item keychain_key
          rescue Net::HTTPServerException => e
            raise e if !e.response.is_a?(Net::HTTPNotFound)
          end
          destroy_item keychain_item
          ui.info "Removed '#{keychain_item["name"]}' from the keychain!"
        end
      end
      
      def destroy_item(data_bag_item)
        data_bag_item.chef_server_rest.delete_rest("data/#{data_bag_item.data_bag}/#{data_bag_item.id}")
      end
    end
  end
end
