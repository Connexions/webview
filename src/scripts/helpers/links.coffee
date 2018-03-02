define (require) ->
  _ = require('underscore')
  Backbone = require('backbone')
  settings = require('settings')
  trim = require('cs!helpers/handlebars/trim')

  shortcodes = settings.shortcodes
  inverseShortcodes = _.invert(shortcodes)

  # For interpolating into reg exps, it has to be a string without
  # the surrounding slashes
  contentPattern =
    ///
    ([^:@/]+)     # uuid up to delimiter
    @?            # Optional @
    ([^:/?]*)     # Revision
    :?            # Optional :
    ([^/?]*)      # Page number or uuid
    /?            # Optional /
    ([^?]*)       # Segment of title
    (\?.*)?       # params (optional)
    ///.toString().slice(1, -1)

  return new class LinksHelper
    contentPattern: contentPattern

    contentsLinkRegEx: ///^contents/#{contentPattern}///

    cleanUrl: trim

    getPath: (page, data, paramsToIgnore = ['cc-view']) ->
      url = settings.root

      switch page
        when 'contents'
          uuid = data.model.getShortUuid()
          version = data.model.get('version')
          uuid += "@#{version}" if version?
          title = data.model.get('title')
          if data.model.isBook() and data.page?
            pageInfo = data.model._lookupPage(data.page)
            pageId = pageInfo?.getShortUuid() ? pageInfo?.id ? data.page
            pageVersion = pageInfo?.get('version')
            title = pageInfo?.get('title')
          url += "contents/#{uuid}"
          url += ":#{pageId}" if pageId
          url += "@#{pageVersion}" if pageVersion?
          url += "/#{trim(title)}" if title
          url += @getCleanSearchQuery(window.location.search, paramsToIgnore)

      return url

    # Get the URL to view a given content model
    getModelPath: (model) ->
      page = ''
      id = model.getUuid?() or model.id
      version = model.get?('version') or model.version
      title = trim(model.get?('title') or model.title)

      if model.isBook?()
        title = trim(model.get('currentPage')?.get('title'))
        page = ":#{model.get('currentPage')?.getShortUuid()}"

      return "#{settings.root}contents/#{id}#{page}/#{title}"

    getCleanSearchQuery: (queryString, paramsToIgnore) ->
      queryString ?= window.location.search

      return queryString if _.isEmpty(paramsToIgnore)

      query = @serializeQuery(queryString)

      cleanedQuery = _.omit(query, paramsToIgnore)
      cleanedQueryString = @param(cleanedQuery)

      if _.isEmpty(cleanedQuery) then '' else "?#{@param(cleanedQuery)}"

    getCurrentPathComponents: () ->
      components = Backbone.history.fragment.match(@contentsLinkRegEx) or []
      path = components[0]
      hash_path = window.location.hash
      components[6] = hash_path
      if path?.slice(-1) is '/'
        path = path.slice(0, -1)

      return {
        path: path
        uuid: components[1]
        version: components[2]
        page: components[3]
        title: components[4]
        rawquery: components[5] or ''
        query: @serializeQuery(components[5] or '')
        hash_path: components[6]
      }

    serializeQuery: (query) ->
      queryString = {}

      query.split('?').pop().split('&').forEach (prop) ->
        item = prop.split('=')
        if item.length is 2
          queryString[decodeURIComponent(item.shift())] = decodeURIComponent(item.shift())

      return queryString

    param: (obj) ->
      str = []

      for p of obj
        if obj.hasOwnProperty(p)
          str.push("#{encodeURI(p)}=#{encodeURI(obj[p])}")

      return str.join("&")

    locationOrigin: () ->
      # Polyfill for location.origin since IE doesn't support it
      port = if location.port then ":#{location.port}" else ''
      location.origin = location.origin or "#{location.protocol}//#{location.hostname}#{port}"

    stripTags: (html) ->
      temp = document.createElement("div")
      temp.innerHTML = html
      return temp.textContent

    offsetHash: () ->
      $pinnable = $('.pinnable')
      obscured = $pinnable.height() + 100
      top = $(window.location.hash)?.offset()?.top
      $(window).scrollTop(top - obscured) if top
