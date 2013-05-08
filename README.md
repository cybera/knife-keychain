knife-keychain
==============

Store keys as encrypted data bag items

Storage example:

```ruby
	knife keychain store yoursite-ssl-certificate certificate_file.pem -E production
```

Add a description and a group for the key:

```ruby
	knife keychain store yoursite-ssl-certificate certificate_file.pem -E production --description "this is an ssl certificate" --group ssl
```

After a description and/or group has been set, subsequent `knife keychain store` commands do not have to specify them (as of v0.1.6). 

The purpose of `description` is simply to better describe what's being stored. `group`, if set, is a way to store keys separately, but retrieve them together. For example:

```ruby
	knife keychain download --group ssl
```

would output all stored keys in the ssl group in a concatenated form.

Retrieval example:
```ruby
	secret = 'your secret encryption key'

	key_record = search(:keychain, "chef_environment:production AND name:yoursite-ssl-certificate").first
	if key_record
		key = Chef::EncryptedDataBagItem.load(:keychain_keys, key_record.id, secret)

		file "/etc/apache2/ssl/yoursite-ssl-certificate.pem" do
			content key['content']
			mode 0600
		end
	end
```

The following is a more involved method you can use in a cookbook to allow "global" keys by using the _default environment to store globals:

```ruby
def keychain_key_for_group(group_name)
  found_keys = {}

  ["_default", node.chef_environment].uniq.each do |current_environment|
    search(:keychain, "chef_environment:#{current_environment} AND group:#{group_name}").each do |key_record|
      key = Chef::EncryptedDataBagItem.load(:keychain_keys, key_record.id)
      found_keys[key_record['name']] = key["content"]
    end
  end

  found_keys.values.join("\n")
end
```

Note that this also will concatenate any keys with the same group name.