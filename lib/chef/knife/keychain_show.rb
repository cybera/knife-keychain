require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainShow < Knife
      include Knife::KeychainBase
      
      banner "knife keychain show NAME (options)"
      
      def run
        search(:keychain, default_conditions.join(" AND ")).each do |keychain_item|
          keychain_key = nil
          begin
            keychain_key = Chef::EncryptedDataBagItem.load(:keychain_keys, keychain_item.id, read_secret).to_hash
          rescue Net::HTTPServerException => e
            raise e if !e.response.is_a?(Net::HTTPNotFound)
            keychain_key = { "content" => "" }
          end

          output_hash = keychain_item.to_hash.merge(keychain_key)
          output_hash.reject! { |k,v| ['_rev', 'chef_type', 'data_bag'].include?(k) }
          output(format_for_display(output_hash))
        end
      end
    end
  end
end
