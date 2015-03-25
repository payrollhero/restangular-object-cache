# restangular-object-cache
R.O.C. The Restangular Object Cache

# What is this?

The Restangular Object Cache is a cache and relationship wiring system for Restangular.
You may use it to attach two Restangular objects together by hasMany or belongsTo
relationships.  You may also use it as a centralized object store for all of the objects
you have received from the server during the lifetime of your application.

# Usage

```coffeescript
  angular.module('my-app',['restangular','restangular-object-cache'])
  angular.module('my-app').factory 'EmployeesService', (Restangular, RestangularObjectCache) ->
    RestangularObjectCache.track 'employees' # tell the object cache to watch the model 'employees'
    RestangularObjectCache.index 'employees', 'account_id' # allow fast lookups by account_id
    RestangularObjectCache.defineRelationships 'employees', (relationships) ->
      relationships.belongsTo 'accounts' # add a method called account()

    return Restangular.service('employees')

  angular.module('my-app').factory 'AccountsService', (Restangular, RestangularObjectCache) ->
     RestangularObjectCache.track 'accounts'
     RestangularObjectCache.defineRelationships 'accounts', (relationships) ->
       relationships.hasMany 'employees' # add a method called employees()

     return Restangular.service('accounts')

  angular.module('my-app').controller 'AccountsController', ($scope, AccountsService, EmployeesService) ->
    EmployeesService.getList().then ->
      AccountsService.getList().then (accounts) ->
        $scope.accounts = accounts

    $scope.employeesForAccount = (account) ->
      account.employees()

```

### Tracking

Use 'track' to add named tracking of a particular model in the cache.  By default they will be tracked by 'id'.

### Relationships

You may use 'hasMany' and 'belongsTo' to wire relationships between models.
