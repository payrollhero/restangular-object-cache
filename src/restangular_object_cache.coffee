#= require_self
#= require_directory .

# @ngdoc module
# @name restangular-object-cache
# @module
mod = angular.module('restangular-object-cache', ['restangular'])
mod.service 'RestangularObjectCache', (Restangular) ->
  guessKeyFromModelName = (modelName) ->
    _.singularize(modelName) + "_id"

  guessModelNameFromSingular = (methodName) ->
    _(methodName).pluralize()

  valuesAt = (object, keys) ->
    for key in keys
      object[key]

  class HasManyDefinition
    constructor: (name, options) ->
      @methodName = name
      @modelName = options.modelName || name
      @modelKey = options.foreignKey
      @primaryKey = options.primaryKey || "id"

    fullfillRelation: (model) ->
      specificCache = objectCaches[@modelName]
      specificCache.allMatchingKey(@modelKey, model[@primaryKey])

  class BelongsToDefinition
    constructor: (methodName, options) ->
      @methodName = methodName
      @modelName = options.modelName || guessModelNameFromSingular(@methodName)
      @modelKey = options.key || guessKeyFromModelName(@modelName)
      @primaryKey = options.primaryKey || "id"

    fullfillRelation: (model) ->
      specificCache = objectCaches[@modelName]
      specificCache.firstMatchingKey(@primaryKey, model[@modelKey])
      
  class HasOneDefinition
    constructor: (methodName, options) ->
      @methodName = methodName
      @modelName = options.modelName || guessModelNameFromSingular(@methodName)
      @modelKey = options.foreignKey || guessKeyFromModelName(@modelName)


  class RelationshipsDefiner
    constructor: (modelName) ->
      @modelName = modelName
      @definitions = []

    hasMany: (methodName, options = {}) ->
      options.foreignKey ||= guessKeyFromModelName(@modelName)
      definition = new HasManyDefinition(methodName, options)
      @definitions.push definition

    belongsTo: (methodName, options = {}) ->
      definition = new BelongsToDefinition(methodName, options)
      @definitions.push(definition)

    hasOne: (methodName, options = {}) ->
      @hasOne(methodName, options)

  class ObjectCache
    constructor: (modelName, primaryKey) ->
      @modelName = modelName
      @primaryKey = primaryKey
      @objects = {}
      @indexes = {}

    addOrUpdateObject: (object) ->
      id = object[@primaryKey]
      if id?
        @removeObject(object)
        @objects[id] = object
      else

      for key, index  of @indexes
        index[object[key]] ||= []
        index[object[key]].push(id)
      return

    removeObject: (object) ->
      id = object[@primaryKey]
      oldObject = @objects[id]
      return unless oldObject
      delete @objects[id]
      for key, index of @indexes
        index[oldObject[key]] = _(index[oldObject[key]] || []).without(id)

    addIndex: (key) ->
      @indexes[key] = {}

    all: ->
      _(@objects).values()

    firstMatchingKey: (keyName, keyValue) ->
      _.first(@allMatchingKey(keyName, keyValue))

    allMatchingKey: (keyName, keyValue) ->
      if keyName == @primaryKey
        [@objects[keyValue]]
      else if _(@indexes).has(keyName)
        ids = (@indexes[keyName][keyValue] || [])
        valuesAt @objects, ids
      else
        whereClause = {}
        whereClause[keyName] = keyValue
        _(@objects).chain().values().where(whereClause).value()

  wireModel = (relationshipsDefiner, model) ->
    _(relationshipsDefiner.definitions).map (definition) ->
      model[definition.methodName] = ->
        definition.fullfillRelation(model)
    return

  wireRelationships = (modelName, model) ->
    relationshipDefiner = relationshipDefinitions[modelName]
    if relationshipDefiner
      wireModel(relationshipDefiner, model)
    return

  addIndex = (modelName, indexName) ->
    objectCaches[modelName].addIndex(indexName)

  createTracking = (modelName, key, service) ->
    specificCache = new ObjectCache(modelName, key)
    objectCaches[modelName] = specificCache
    service.extendModel modelName, (model) ->
      specificCache.addOrUpdateObject(model)
      wireRelationships(modelName, model)
      return model

  validateModelName = (modelName) ->
    unless objectCaches[modelName]
      throw "Not currently tracking #{modelName}!  Use RestangularObjectCache.track(#{modelName})"

  #our most fundamental store.
  objectCaches = {}
  relationshipDefinitions = {}

  @defineRelationships = (modelName, definitionCb) ->

    relationshipDefinitions[modelName] = new RelationshipsDefiner(modelName)
    definitionCb(relationshipDefinitions[modelName])

  @index = (modelName, indexName) ->
    addIndex(modelName, indexName)
    return

  @removeObject = (modelName, object) ->
    validateModelName(modelName)
    objectCaches[modelName].removeObject(object)

  @all = (modelName) ->
    validateModelName(modelName)
    objectCaches[modelName].all()

  @allBy = (modelName, attribute, value) ->
    validateModelName(modelName)
    objectCaches[modelName].allMatchingKey(attribute, value)

  @track = (modelName, options = {}) ->
    options.key ||= 'id'
    options.service ||= Restangular
    createTracking(modelName, options.key, options.service)

  @clear = ->
    objectCaches = {}
    relationshipDefinitions = {}

  return

module.exports = mod;
