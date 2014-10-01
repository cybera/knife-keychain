knife-keychain
==============

Store keys as encrypted data bag items

### Basic usage example:

```console
knife keychain store yoursite-ssl-certificate certificate_file.pem -E production
```

*Add a description and a group for the key:*

```console
knife keychain store yoursite-ssl-certificate certificate_file.pem -E production --description "this is an ssl certificate" --group ssl
```

After a description and/or group has been set, subsequent `knife keychain store` commands do not have to specify them (as of v0.1.6).

### Options:

The purpose of `--description` is simply to better describe what's being stored. `--group`, if set, is a way to store keys separately, but retrieve them together. For example:

```console
knife keychain download --group ssl
```

would output all stored keys in the ssl group in a concatenated form.

`--global` specifies to look at or work with only keys at the global level (shared by all environments).

`--environment` works as it does in other knife commands. It will constrain the command to work within the environment you specify.

### Creating, modifying, and removing keys:

Create a brand new key for the production environment:

```console
knife keychain store some-key-name files/some-key-file --group ssl-key --description "private key for ssl cert" --environment production
```

Update the key you created with content from another file:

```console
knife keychain store some-key-name files/some-other-key-file --environment production
```

Delete your key from the production environment

```console
knife keychain remove some-key-name --environment production
```

### Displaying keys:

List only global-level keys

```console
knife keychain list --global
```

List only keys that are specific to the production environment

```console
knife keychain list --no-global --environment production
```

List keys specific to the production environment, inheriting any from the global level if they are not overridden

```console
knife keychain list --environment production
```

Show meta-information and decrypted content of a key

```console
knife keychain show some-key-name
```

Show all information about keys in the "git" group

```console
knife keychain show --group git
```

Download the raw decrypted key content:

```console
knife keychain download some-key-name >downloaded-key.pem
```

### Copying keys:

Copy all keys unique to SOME_ENVIRONMENT into OTHER_ENVIRONMENT

```console
knife keychain copy --source-environment SOME_ENVIRONMENT --destination-environment OTHER_ENVIRONMENT
```

Copy a single key unique to SOME_ENVIRONMENT into OTHER_ENVIRONMENT

```console
knife keychain copy --source-environment SOME_ENVIRONMENT --destination-environment OTHER_ENVIRONMENT SINGLE_KEY_NAME
```

Note: the copy command will not copy *global* keys (indicated with \* to the left of the name in a key listing),
as these keys are not actually in the source-environment (they're inherited from the \_default environment). To
see what the command will actually copy, run `knife keychain list --environment SOME_ENVIRONMENT --no-global`.

### Usage in cookbooks:

Simplest retrieval example:

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

knife-keychain is really just an easy way to work with two databags: *keychain* (plain) and *keychain_keys* (encrypted). If you want, you can operate with either data bag directly via the typical knife data bag tools. You can also use the information in any way you would use regular data bags within your recipes. However, due to the use of the _default environment as a "global" level which your other environments can inherit from, you'll likely want to do something like this:

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

Note that this also will concatenate any keys with the same group name. It will "override" any key defined in the _default environment with one defined in your node's environment.
