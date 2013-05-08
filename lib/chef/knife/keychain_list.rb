require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainList < Knife
      include Knife::KeychainBase
      
      option :global,
      :long  => "--[no-]global",
      :boolean => true,
      :description => "Include global keys in the list (default: true)",
      :default => nil

      banner "knife keychain list (options)"

      def run
        key_list = []
        key_defs = {}

        [((config[:global].nil? || config[:global]) ? "_default" : nil), (config[:global] ? nil : environment)].compact.uniq.each do |current_environment|
          search(:keychain, default_conditions(current_environment).join(" AND ")).each do |keychain_item|
            key_list << keychain_item['name']
            key_defs[keychain_item['name']] = keychain_item
          end
        end

        output("")

        key_list.uniq.sort.each do |key_name|
          extra = key_defs[key_name]['group'] ? " (#{key_defs[key_name]['group']})" : ""
          extra += key_defs[key_name]['description'] ? ": #{key_defs[key_name]['description']}" : ""
          
          is_global = ( key_defs[key_name]['chef_environment'] == "_default" )
          output(format_for_display((is_global ? "*" : " ") + ui.color(key_name, :cyan) + extra))
        end

        output("")
      end
    end
  end
end
