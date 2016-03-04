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

      option :query,
      :long => "--query",
      :description => "Reencrypt all keys matching the query (expects the main parameter to be a query, not a name)",
      :boolean => true,
      :default => false

      banner "knife keychain reencrypt NAME|QUERY (options)"
      
      def run
        # Initialize the keychain and keychain_keys data bags
        keychain_bag
        keychain_keys_bag

        validate!

        if config[:query]
          query = key_name
          keychain_items = search(:keychain, query)
          keychain_item_names = keychain_items.map do |keychain_item|
            "#{keychain_item[:name]} #{_global_indicator(keychain_item)}"
          end.join("\n")
          confirm("\n#{keychain_item_names}\n\nDo you really want to reencrypt the above keys from the keychain")
        else
          keychain_items = search(:keychain, "chef_environment:#{environment} AND name:#{key_name}")
        end

        keychain_items.each do | keychain_item |
          keychain_key = read_key(keychain_item, [config[:current_key_file], config[:new_key_file]])
          store_key(keychain_item, keychain_key, config[:new_key_file])

          ui.info "Reencrypted '#{keychain_item[:name]}' #{_global_indicator(keychain_item)}!\n"
        end
      end

      def validate!
        
        error_messages = []
        if !config[:current_key_file]
          error_messages << "Must set --current-key-file option"
        end
        
        if !config[:new_key_file] && (!read_secret || read_secret == "")
          error_messages << "Must either set --new-key-file option or have knife[:secret_file] set in your config"
        end
        
        if error_messages.any?
          error_messages.each do | error_message |
            ui.error(error_message)
          end
          exit 1
        end
      end

      def _global_indicator(keychain_item)
        if keychain_item[:chef_environment] == "_default"
          "(as a global key)"
        else
          "(#{keychain_item[:chef_environment]})"
        end
      end
    end
  end
end
