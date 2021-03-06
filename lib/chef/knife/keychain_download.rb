require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainDownload < Knife
      include Knife::KeychainBase
      
      option :global,
      :long  => "--[no-]global",
      :boolean => true,
      :description => "Show the global version of the key, even if it is overridden in the local environment (default: false)",
      :default => false

      banner "knife keychain download NAME (options)"
      
      def run
        store_environment = (config[:global] ? "_default" : environment)
        found_keys = {}

        search(:keychain, default_conditions("_default").join(" AND ")).each do |keychain_item|
          found_keys[keychain_item['name']] = keychain_item
        end

        search(:keychain, default_conditions(store_environment).join(" AND ")).each do |keychain_item|
          found_keys[keychain_item['name']] = keychain_item
        end if !config[:global]
        
        found_keys.values.each do |keychain_item|
          keychain_key = nil
          begin
            keychain_key = Chef::EncryptedDataBagItem.load(:keychain_keys, keychain_item.id, read_secret).to_hash
          rescue Net::HTTPServerException => e
            raise e if !e.response.is_a?(Net::HTTPNotFound)
            keychain_key = { "content" => "" }
          end

          msg(keychain_key["content"])
        end
      end
    end
  end
end
