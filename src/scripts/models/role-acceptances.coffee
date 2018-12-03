define (require) ->
  Backbone = require('backbone')
  settings = require('json!settings.json')

  authoringport = if settings.cnxauthoring.port then ":#{settings.cnxauthoring.port}" else ''
  AUTHORING = "#{location.protocol}//#{settings.cnxauthoring.host}#{authoringport}"

  return class RoleAcceptance extends Backbone.Model
    url: () -> "#{AUTHORING}/contents/#{@contentId}@draft/acceptance"

    initialize: (options) =>
      @contentId = options.id
      @fetch
        reset: true,
        xhrFields: withCredentials: true
      .fail (response) =>
        @set('error', response?.status or 9000)

    save: (key, val, options) ->
      if not key? or typeof key is 'object'
        attrs = key
        options = val
      else
        attrs = {}
        attrs[key] = val

      options = _.extend(
        dataType: 'xml'
        xhrFields:
          withCredentials: true
      , options)

      return super(attrs, options)
