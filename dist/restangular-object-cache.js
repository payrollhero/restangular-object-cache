var mod;

mod = angular.module('restangular-object-cache', ['restangular']);

mod.service('RestangularObjectCache', function(Restangular) {
  var HasManyDefinition, HasOneDefinition, ObjectCache, RelationshipsDefiner, addIndex, createTracking, guessKeyFromModelName, guessModelNameFromSingular, objectCaches, relationshipDefinitions, validateModelName, valuesAt, wireModel, wireRelationships;
  guessKeyFromModelName = function(modelName) {
    return _.singularize(modelName) + "_id";
  };
  guessModelNameFromSingular = function(methodName) {
    return _(methodName).pluralize();
  };
  valuesAt = function(object, keys) {
    var i, key, len, results;
    results = [];
    for (i = 0, len = keys.length; i < len; i++) {
      key = keys[i];
      results.push(object[key]);
    }
    return results;
  };
  HasManyDefinition = (function() {
    function HasManyDefinition(name, options) {
      this.methodName = name;
      this.modelName = options.modelName || name;
      this.modelKey = options.foreignKey;
      this.primaryKey = options.primaryKey || "id";
    }

    HasManyDefinition.prototype.fullfillRelation = function(model) {
      var specificCache;
      specificCache = objectCaches[this.modelName];
      return specificCache.allMatchingKey(this.modelKey, model[this.primaryKey]);
    };

    return HasManyDefinition;

  })();
  HasOneDefinition = (function() {
    function HasOneDefinition(methodName, options) {
      this.methodName = methodName;
      this.modelName = options.modelName || guessModelNameFromSingular(this.methodName);
      this.modelKey = options.key || guessKeyFromModelName(this.modelName);
      this.primaryKey = options.primaryKey || "id";
    }

    HasOneDefinition.prototype.fullfillRelation = function(model) {
      var specificCache;
      specificCache = objectCaches[this.modelName];
      return specificCache.firstMatchingKey(this.primaryKey, model[this.modelKey]);
    };

    return HasOneDefinition;

  })();
  RelationshipsDefiner = (function() {
    function RelationshipsDefiner(modelName) {
      this.modelName = modelName;
      this.definitions = [];
    }

    RelationshipsDefiner.prototype.hasMany = function(methodName, options) {
      var definition;
      if (options == null) {
        options = {};
      }
      options.foreignKey || (options.foreignKey = guessKeyFromModelName(this.modelName));
      definition = new HasManyDefinition(methodName, options);
      return this.definitions.push(definition);
    };

    RelationshipsDefiner.prototype.hasOne = function(methodName, options) {
      var definition;
      if (options == null) {
        options = {};
      }
      definition = new HasOneDefinition(methodName, options);
      return this.definitions.push(definition);
    };

    RelationshipsDefiner.prototype.belongsTo = function(methodName, options) {
      if (options == null) {
        options = {};
      }
      return this.hasOne(methodName, options);
    };

    return RelationshipsDefiner;

  })();
  ObjectCache = (function() {
    function ObjectCache(modelName, primaryKey) {
      this.modelName = modelName;
      this.objects = {};
      this.primaryKey = primaryKey;
      this.indexes = {};
    }

    ObjectCache.prototype.addOrUpdateObject = function(object) {
      var id, index, key, name1, ref;
      id = object[this.primaryKey];
      this.removeObject(object);
      this.objects[id] = object;
      ref = this.indexes;
      for (key in ref) {
        index = ref[key];
        index[name1 = object[key]] || (index[name1] = []);
        index[object[key]].push(id);
      }
    };

    ObjectCache.prototype.removeObject = function(object) {
      var id, index, key, oldObject, ref, results;
      id = object[this.primaryKey];
      oldObject = this.objects[id];
      if (!oldObject) {
        return;
      }
      delete this.objects[id];
      ref = this.indexes;
      results = [];
      for (key in ref) {
        index = ref[key];
        results.push(index[oldObject[key]] = _(index[oldObject[key]] || []).without(id));
      }
      return results;
    };

    ObjectCache.prototype.addIndex = function(key) {
      return this.indexes[key] = {};
    };

    ObjectCache.prototype.all = function() {
      return _(this.objects).values();
    };

    ObjectCache.prototype.firstMatchingKey = function(keyName, keyValue) {
      return _.first(this.allMatchingKey(keyName, keyValue));
    };

    ObjectCache.prototype.allMatchingKey = function(keyName, keyValue) {
      var ids, whereClause;
      if (keyName === this.primaryKey) {
        return [this.objects[keyValue]];
      } else if (_(this.indexes).has(keyName)) {
        ids = this.indexes[keyName][keyValue] || [];
        return valuesAt(this.objects, ids);
      } else {
        whereClause = {};
        whereClause[keyName] = keyValue;
        return _(this.objects).chain().values().where(whereClause).value();
      }
    };

    return ObjectCache;

  })();
  wireModel = function(relationshipsDefiner, model) {
    var definition, i, len, ref;
    ref = relationshipsDefiner.definitions;
    for (i = 0, len = ref.length; i < len; i++) {
      definition = ref[i];
      model[definition.methodName] = function() {
        return definition.fullfillRelation(model);
      };
    }
  };
  wireRelationships = function(modelName, model) {
    var relationshipDefiner;
    relationshipDefiner = relationshipDefinitions[modelName];
    if (relationshipDefiner) {
      wireModel(relationshipDefiner, model);
    }
  };
  addIndex = function(modelName, indexName) {
    return objectCaches[modelName].addIndex(indexName);
  };
  createTracking = function(modelName, key, service) {
    var specificCache;
    specificCache = new ObjectCache(modelName, key);
    objectCaches[modelName] = specificCache;
    return service.extendModel(modelName, function(model) {
      specificCache.addOrUpdateObject(model);
      wireRelationships(modelName, model);
      return model;
    });
  };
  validateModelName = function(modelName) {
    if (!objectCaches[modelName]) {
      throw "Not currently tracking " + modelName + "!  Use RestangularObjectCache.track(" + modelName + ")";
    }
  };
  objectCaches = {};
  relationshipDefinitions = {};
  this.defineRelationships = function(modelName, definitionCb) {
    relationshipDefinitions[modelName] = new RelationshipsDefiner(modelName);
    return definitionCb(relationshipDefinitions[modelName]);
  };
  this.index = function(modelName, indexName) {
    addIndex(modelName, indexName);
  };
  this.removeObject = function(modelName, object) {
    validateModelName(modelName);
    return objectCaches[modelName].removeObject(object);
  };
  this.all = function(modelName) {
    validateModelName(modelName);
    return objectCaches[modelName].all();
  };
  this.allBy = function(modelName, attribute, value) {
    validateModelName(modelName);
    return objectCaches[modelName].allMatchingKey(attribute, value);
  };
  this.track = function(modelName, options) {
    if (options == null) {
      options = {};
    }
    options.key || (options.key = 'id');
    options.service || (options.service = Restangular);
    return createTracking(modelName, options.key, options.service);
  };
  this.clear = function() {
    objectCaches = {};
    return relationshipDefinitions = {};
  };
});
