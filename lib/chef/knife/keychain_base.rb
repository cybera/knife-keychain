require 'chef/knife'

class Chef
  class Knife
    module KeychainBase
      def self.included(includer)
        includer.class_eval do
          option :secret,
          :short => "-s SECRET",
          :long  => "--secret ",
          :description => "The secret key to use to encrypt data bag item values"

          option :secret_file,
          :long => "--secret-file SECRET_FILE",
          :description => "A file containing the secret key to use to encrypt data bag item values"
          
          option :group,
          :short => "-g GROUP",
          :long => "--group GROUP",
          :description => "An optional group, which can be searched. The default is no group."
        end
      end
      
      def environment
        config[:environment] ||= (Chef::Config[:environment] || '_default')
        config[:environment]
      end

      def key_name
        name_args[0]
      end
      
      def key_file_path
        name_args[1]
      end

      def keychain_bag
        begin
          @keychain_bag ||= Chef::DataBag.load("keychain")
        rescue Net::HTTPServerException => e
          ui.info "keychain data bag does not exist - creating..."
          @keychain_bag = Chef::DataBag.new
          @keychain_bag.name("keychain")
          @keychain_bag.save
        end
        
        @keychain_bag
      end

      def keychain_keys_bag
        begin
          @keychain_keys_bag ||= Chef::DataBag.load("keychain_keys")
        rescue Net::HTTPServerException => e
          ui.info "keychain_keys data bag does not exist - creating..."
          @keychain_keys_bag = Chef::DataBag.new
          @keychain_keys_bag.name("keychain_keys")
          @keychain_keys_bag.save
        end
        
        @keychain_keys_bag
      end

      def search(data_bag_name, conditions)
        query = Chef::Search::Query.new
        # The response from a query is in the following array format:
        #
        #   [ response["rows"], response["start"], response["total"] ]
        #
        # which is kind of confusing when you don't need the rest of the data. In our case, 
        # we don't... thus this wrapper method!
        query.search(data_bag_name, conditions).first
      end
      
      def read_secret
        if config[:secret]
          config[:secret]
        else
          Chef::EncryptedDataBagItem.load_secret(config[:secret_file])
        end
      end
      
      def default_conditions
        conditions = ["chef_environment:#{environment}"]
        conditions << "name:#{key_name}" if key_name
        conditions << "group:#{config[:group]}" if config[:group]
        conditions
      end
    end
  end
end

