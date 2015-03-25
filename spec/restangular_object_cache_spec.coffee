'use strict'

describe 'RestangularObjectCache', ->
  initializeModule()
  $httpBackend = {}

  describe 'tracking', ->
    subject = {}
    service = {}
    before ->
      angular.module('restangular-object-cache').factory 'EmployeesService', (Restangular, RestangularObjectCache) ->
        RestangularObjectCache.track 'employees'
        RestangularObjectCache.index 'employees', 'account_id'

        return Restangular.service('employees')

    before inject (_RestangularObjectCache_, _EmployeesService_, _$httpBackend_) ->
      subject = _RestangularObjectCache_
      service = _EmployeesService_
      $httpBackend = _$httpBackend_
      $httpBackend.expectGET("/employees").respond(getJSONFixture('employees_response.json'))
      service.getList()
      $httpBackend.flush()

    afterEach ->
      subject.clear()

    it "caches all objects received from the server", ->
      expect(_(subject.all('employees')).pluck("id")).toEqual([1, 2, 3])

    it "indexes the employees on account_id", ->
      expect(_(_(subject.allBy('employees','account_id', 1))).pluck("id")).toEqual([1,2])
      expect(_(_(subject.allBy('employees','account_id', 2))).pluck("id")).toEqual([3])

    it "can query on non indexed things", ->
      expect(_(_(subject.allBy('employees','other_id', 1))).pluck("id")).toEqual([2,3])
      expect(_(_(subject.allBy('employees','other_id', 2))).pluck("id")).toEqual([1])

    it 'removing an object removes it', ->
      employee = subject.all('employees')[0]
      subject.removeObject('employees', employee)
      expect(_(subject.all('employees')).pluck("id")).toEqual([2, 3])
      expect(_(_(subject.allBy('employees','account_id', 1))).pluck("id")).toEqual([2])
      expect(_(_(subject.allBy('employees','other_id', 2))).pluck("id")).toEqual([])

  describe 'hasMany and belongsTo', ->
    subject = {}
    EmployeesService = {}
    AccountsService = {}
    before ->
      angular.module('restangular-object-cache').factory 'EmployeesService', (Restangular, RestangularObjectCache) ->
        RestangularObjectCache.track 'employees'
        RestangularObjectCache.index 'employees', 'account_id'
        RestangularObjectCache.defineRelationships 'employees', (relationships) ->
          relationships.belongsTo 'account'

        return Restangular.service('employees')

      angular.module('restangular-object-cache').factory 'AccountsService', (Restangular, RestangularObjectCache) ->
        RestangularObjectCache.track 'accounts'
        RestangularObjectCache.defineRelationships 'accounts', (relationships) ->
          relationships.hasMany 'employees'

        return Restangular.service('accounts')

    before inject (_RestangularObjectCache_, _EmployeesService_, _AccountsService_, _$httpBackend_) ->
      subject = _RestangularObjectCache_
      EmployeesService = _EmployeesService_
      AccountsService = _AccountsService_
      $httpBackend = _$httpBackend_
      $httpBackend.expectGET("/employees").respond(getJSONFixture('employees_response.json'))
      $httpBackend.expectGET("/accounts").respond(getJSONFixture('accounts_response.json'))
      EmployeesService.getList()
      AccountsService.getList()
      $httpBackend.flush()

    it 'hangs employees of of the accounts', ->
      accounts = subject.all('accounts')
      expect(_(accounts[0].employees()).pluck("id")).toEqual([1, 2])
      expect(_(accounts[1].employees()).pluck("id")).toEqual([3])

    it 'hangs the account of of the employees', ->
      employees = subject.all('employees')
      expect(employees[0].account().id).toEqual(1)


