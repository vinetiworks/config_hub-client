# Ruby ConfigHub client
### Setup
```ruby
client = ConfigHubApi::Client.new(
    'https://config.example.com',
    'your-confighub-token',
    'context1;context2;context3'
)
# this requests config for your context from the server and stores it in the client
# you can call it again to refresh the data
client.pull 
```
### Usage
```ruby
# do this when you want to get a configuration value
# this does not request data from the server
value = client.fetch('your.config.key') { 'default value' }
```