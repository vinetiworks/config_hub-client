# Ruby ConfigHub client

### Installation
Add this to your Gemfile:
```ruby
gem 'config_hub-client'
```
then `bundle install`

Or install globally:

`gem install config_hub-client`

### Setup
```ruby
# create a client instance
client = ConfigHub::Client.new(
    'https://config.example.com',
    'your-confighub-token',
    'context1;context2;context3'
)
 
# request config for your context from the server and store it locally
# you can call it again to refresh the data
client.pull

# create a client instance with options
client = ConfigHub::Client.new(
    'https://config.example.com',
    'your-confighub-token',
    'context1;context2;context3',
    { tag: 'yourtaglabel' }
)
```

### Usage
```ruby
# get a configuration value from local cache
# does not request data from the server
value = client.fetch('your.config.key') { 'default value' }

# get a file's contents
file = client.fetch_file('your.file.key')

# if you have pulled config without the No-Files option 
# the file will be returned from local cache

# if you have not pulled, or have pulled with the No-Files option
# then a request will be made to /rest/rawFile
```
