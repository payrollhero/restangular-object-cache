#= require_self
#= require_directory .

# @ngdoc module
# @name payrollhero.api
# @module
mod = angular.module('restangular-roc', ['restangular'])
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

  class HasOneDefinition
    constructor: (methodName, options) ->
      @methodName = methodName
      @modelName = options.modelName || guessModelNameFromSingular(@methodName)
      @modelKey = options.key || guessKeyFromModelName(@modelName)
      @primaryKey = options.primaryKey || "id"

    fullfillRelation: (model) ->
      specificCache = objectCaches[@modelName]
      specificCache.firstMatchingKey(@primaryKey, model[@modelKey])

  class RelationshipsDefiner
    constructor: (modelName) ->
      @modelName = modelName
      @definitions = []

    hasMany: (methodName, options = {}) ->
      options.foreignKey ||= guessKeyFromModelName(@modelName)
      definition = new HasManyDefinition(methodName, options)
      @definitions.push definition

    hasOne: (methodName, options = {}) ->
      definition = new HasOneDefinition(methodName, options)
      @definitions.push(definition)

  class ObjectCache
    constructor: (modelName, primaryKey) ->
      @modelName = modelName
      @objects = {}
      @primaryKey = primaryKey
      @indexes = {}

    addObject: (object) ->
      console.log("Adding object to cache #{@modelName}", object)
      id = object[@primaryKey]
      @objects[id] = object
      for key, index  of @indexes
        index[object[key]] ||= []
        index[object[key]].push(id)
      return

    removeObject: (object) ->
      console.log("Removing object from cache #{@modelName}", object)
      id = object[@primaryKey]
      delete @objects[id]
      for key, index of @indexes
        index[object[key]] = _(index[object[key]] || []).without(id)

    addIndex: (key) ->
      @indexes[key] = {}

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
    for definition in relationshipsDefiner.definitions
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
      specificCache.addObject(model)
      wireRelationships(modelName, model)
      return model

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
    objectCaches[modelName].removeObject(object)

  @track = (modelName, options = {}) ->
    options.key ||= 'id'
    options.service ||= Restangular
    createTracking(modelName, options.key, options.service)

  return
