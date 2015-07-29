# MongoSpy
Spy on a Mongo connection. Filter out housekeeping queries and their responses.
This is not thread-safe so there should be one instance of this proxy for each
connection you want to spy on.

## Installation
This script is written in Ruby and uses the mongo-proxy and trollop libraries.
Before running the script, you may need to do:
```
gem install mongo-proxy
gem install trollop
```

## Usage
For options, give the command:
```
./mongospy.rb -h
```
