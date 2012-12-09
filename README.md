# Flock of Chefs

Flock of Chefs provides inter-node communication primatives to Chef instances.

## Important note

This is highly experimental. It is not recommended near any environment
where stability is an even remote priority. Currently this is a proof of 
concept to show that it can work and to get feedback on some use cases it 
can solve and how it can be made better.

## How does it work

Flock of Chefs uses DCell to provide inter-node communications. It uses Celluloid
actors to provide APIs with with remote nodes can interact. It also persists
resources allowing for out of band action notifications.

## Wait, what?

Yep, resources are persisted after the convergence has completed. This allows
resources to be defined during the Chef run that subscribe to remote resouces.
Since remote convergence may not be occurring in a timely manner, we want to
allow the local convergence to continue on, allowing the resources with
remote subscriptions to run when they are notified.

## What's the API look like?

Currently the `:flock_api` is considered the public API provided via Flock.
A `:resource_manager` actor exists, and can happily be used, but be warned
it is highly prone to change as it is used internally for remote notifications
and subscriptions.

Methods provided from the `:flock_api`
* `run_chef` - Triggers a chef run on the node
* `active` - Returns if chef is currently running on the node

Example of triggering a Chef client run:

```ruby
FlockOfChefs['bender0'][:flock_api].run_chef
```

## Usage

### Remote notifications

```ruby
# On node bender0
file '/tmp/fubar' do
  action :create
  content 'foobar'
  remote_notifies :run, 'execute[kill all humans]', :node => 'bender1'
end
```

When the node bender0 converges, if the file[/tmp/fubar] resource
runs, it will trigger a remote notification. The remote notification
will send the `run` action to the the execute[kill all humans]
resource on the bender1 node.

### Remote Subscriptions
```ruby
# On node bender1
file '/tmp/fubar' do
  action :nothing
  content 'foobar'
  remote_subscribes :create, 'execute[kill all humans]', :node => 'bender0'
end
```

### Wait for desired state
```ruby
file '/tmp/fubar' do
  action :create
  content 'foobar'
  wait_until do
    FlockOfChefs['bender0'][:flock_api].active
  end
end
```

### Wait while specific state exists
```ruby
file '/tmp/fubar' do
  action :create
  content 'foobar'
  wait_while do
    FlockOfChefs['bender0'][:flock_api].active
  end
end
```

## Library Info

* Repository: https://github.com/chrisroberts/flock_of_chefs
* Cookbook Repository: https://github.com/chrisrobrts/cookbook-flock_of_chefs
