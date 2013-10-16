# Everyday Dart

Everyday Dart is an overview of some of the things I've learned as I go about building client/server web applications using polymer.dart 
and dart.

## The example


### Overview
The example (example/showcase) is very basic web application that allows adding and editing profiles stored in a 
postgresql database.  It covers:

- convert
- history management
- isolates
- mirrors
- polymer
- rpc
- serialization
- streams
- timeouts
- websockets
- xxgregs postgresql library

### Running the example

_Configuration is hardcoded in example/showcase/server/server.dart_

- Create a postgresql database
  - Install a postgresql database (port 5432) and ensure that dev.local resolves to the postgresql host.
  - Create a postgresql user dev with the password dev
  - Run the sql for creating profiles\_sequence and profiles found in example/showcase/server/postgresql\_persistence_handlers.dart

- Run example/showcase/server/server.dart
- Run example/showcase/client/index.html in dartium
- Users and passwords are not currently implemented, so just click sign in.
