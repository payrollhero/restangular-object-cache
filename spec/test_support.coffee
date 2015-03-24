window.itPromises = (message, testFunc) ->
  it message, (done) ->
    successCb = sinon.spy()
    testFunc.apply(this, []).then(successCb).catch (error) ->
      console.error "Unhandled failure from test: #{error}"
      expect(false).toBeTruthy()
    .finally ->
      done()

window.promiseBefore = (beforeFunc) ->
  beforeEach (done) ->
    beforeFunc.apply(this, []).finally(done)

window.before = beforeEach

window.initializeModule = ->
  before ->
      module('angular-advanced-poller')
