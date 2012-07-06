knife-keychain
==============

Store keys as encrypted data bag items

Storage example:

	knife keychain store yoursite-ssl-certificate certificate_file.pem -E production

Retrieval example:

	secret = 'your secret encryption key'

	key_record = search(:keychain, "chef_environment:production AND name:yoursite-ssl-certificate").first
	if key_record
		key = Chef::EncryptedDataBagItem.load(:keychain_keys, key_record.id, secret)

		file "/etc/apache2/ssl/yoursite-ssl-certificate.pem" do
			content key['content']
			mode 0600
		end
	end