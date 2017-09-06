# Ruby ConfigHub client

### Installation
Gemfile
```ruby
gem 'config_hub-client'
```

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
```

### Usage
```ruby
# get a configuration value from local cache
# does not request data from the server
value = client.fetch('your.config.key') { 'default value' }
```