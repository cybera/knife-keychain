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
          @keychain_bag.create
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
          @keychain_keys_bag.create
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

      def read_secret(secret_file=nil)
        if secret_file
          Chef::EncryptedDataBagItem.load_secret(secret_file)
        else
          if config[:secret]
            config[:secret]
          else
            Chef::EncryptedDataBagItem.load_secret(config[:secret_file])
          end
        end
      end

      def default_conditions(search_environment=environment)
        conditions = ["chef_environment:#{search_environment}"]
        conditions << "name:#{key_name}" if key_name
        conditions << "group:#{config[:group]}" if config[:group]
        conditions
      end

      def read_key(keychain_item, secret_files=nil)
        secrets = [ secret_files ].flatten.compact.map { | secret_file | read_secret(secret_file) }

        decryption_failure = nil
        keychain_key = nil
        secrets.each do | secret |
          begin
            keychain_key = Chef::EncryptedDataBagItem.load(:keychain_keys, keychain_item.id, secret).to_hash
            break
          rescue Chef::EncryptedDataBagItem::DecryptionFailure => e
            decryption_failure = e
          rescue Net::HTTPServerException => e
            if e.response.is_a?(Net::HTTPNotFound)
              keychain_key = {
                "id" => keychain_item.id,
                "content" => ""
              }
            else
              raise e
            end
          end
        end

        if !keychain_key && decryption_failure
          puts "None of the previous secrets provided could decrypt the keychain data"
          raise decryption_failure
        end
        
        keychain_key["content"]
      end

      def store_key(keychain_item, key, secret_file=nil)
        secret = read_secret(secret_file)

        keychain_key = {
          "id" => keychain_item.id,
          "content" => key
        }

        encrypted_keychain_key = Chef::DataBagItem.from_hash(Chef::EncryptedDataBagItem.encrypt_data_bag_item(keychain_key, secret))
        encrypted_keychain_key.data_bag("keychain_keys")
        encrypted_keychain_key.save
      end

      def validate!
      end
    end
  end
end
