require 'chef/knife'
require 'chef/knife/keychain_base'

class Chef
  class Knife
    class KeychainCopy < Knife
      include Knife::KeychainBase

      option :source_environment,
      :long  => "--source-environment NAME",
      :description => "source environment name",
      :default => false

      option :destination_environment,
      :long  => "--destination-environment NAME",
      :description => "destination environment name",
      :default => false
      
      banner "knife keychain copy (options)"

      def run
        validate!

        key_list = []
        key_defs = {}

        output("")

        search(:keychain, default_conditions(config[:source_environment]).join(" AND ")).each do |keychain_item|
          copy_keychain_item(keychain_item, config[:destination_environment])
          ui.info "copied #{keychain_item['name']} from #{config[:source_environment]} to #{config[:destination_environment]}"
        end

        output("")
      end

      def copy_keychain_item(keychain_item, to_environment)
        dup_keychain_item = search(:keychain, "chef_environment:#{to_environment} AND name:#{keychain_item['name']}").first || Chef::DataBagItem.new
        dup_keychain_item.data_bag("keychain")
        dup_keychain_item.raw_data = {
          "id" => "#{to_environment}---#{keychain_item['name']}",
          "chef_environment" => to_environment,
          "name" => keychain_item['name'],
          "group" => keychain_item['group'],
          "description" => keychain_item['description']
        }
        dup_keychain_item.save

        store_key(dup_keychain_item, read_key(keychain_item))
      end

      def validate!
        errors = []
        errors << "Need to give a --source-environment" if !config[:source_environment]
        errors << "Need to give a --destination-environment" if !config[:destination_environment]

        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end
    end
  end
end
