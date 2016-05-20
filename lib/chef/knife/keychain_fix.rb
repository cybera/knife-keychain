require 'chef/knife'
require 'chef/knife/keychain_base'

# Purpose: 
#
# Programmatically fix various issues with a set of keys in the keychain.
# 
# Issue 1: Missing 'name' attribute
#
# When you edit a keychain item as a data bag item, the 'name' attribute
# can be removed, likely because it is being treated as a special attribute
# of data bag items, even though that is under a different scope. The fix
# for this issue will be to reset the name attribute by deriving it from the
# id of the keychain item (which happens to be a combination of the environment
# name and the keychain item name). A 'keyname' attribute will also be set on
# all keychain items that don't have it. 'keyname' will be an exact copy of
# 'name'. This will support moving away from using 'name' and the problems it
# entails in the future.

class Chef
  class Knife
    class KeychainFix < Knife
      include Knife::KeychainBase
      
      option :global,
      :long  => "--[no-]global",
      :boolean => true,
      :description => "Include global keys (default: true)",
      :default => nil

      banner "knife keychain fix (options)"

      def run
        keychain_item_list = []

        [((config[:global].nil? || config[:global]) ? "_default" : nil), (config[:global] ? nil : environment)].compact.uniq.each do |current_environment|
          search(:keychain, default_conditions(current_environment).join(" AND ")).each do |keychain_item|
            keychain_item_list << keychain_item
          end
        end

        output("")

        problems = []

        __each_keychain_item_without_name(keychain_item_list) do |item,potential_name|
          problems << "#{item.id} is missing its name. Will be updated to: #{potential_name}"
        end

        __each_keychain_item_without_keyname(keychain_item_list) do |item,name|
          problems << "#{item.id} is missing a keyname. Will be updated to: #{name}"
        end

        message = <<-EOS
The following problems exist and will be corrected:
        
#{problems.join("\n")}
EOS
        if confirm("#{message}\nProceed")
          __each_keychain_item_without_name(keychain_item_list) do |item,potential_name|
            item['name'] = potential_name
            item.save
          end
          
          __each_keychain_item_without_keyname(keychain_item_list) do |item,name|
            item['keyname'] = name
            item.save
          end
        end
        output("")
      end
      
      def __each_keychain_item_without_name(item_list, &block)
        item_list.each do |keychain_item|
          if !keychain_item['name']
            potential_name = keychain_item.id.gsub(/(.*)---(.*)/,'\2')
            yield(keychain_item, potential_name)
          end
        end
      end

      def __each_keychain_item_without_keyname(item_list, &block)
        item_list.each do |keychain_item|
          if !keychain_item['keyname']
            potential_name = keychain_item.id.gsub(/(.*)---(.*)/,'\2')
            yield(keychain_item, keychain_item['name'] || potential_name)
          end
        end
      end
    end
  end
end
