define (require) ->
  _ = require('underscore')
  session = require('cs!session')
  settings = require('settings')
  linksHelper = require('cs!helpers/links')
  router = require('cs!router')
  EditableView = require('cs!helpers/backbone/views/editable')
  BookPopoverView = require('cs!./popovers/book/book')
  template = require('hbs!./header-template')
  require('less!./header')

  return class MediaHeaderView extends EditableView
    media: 'page'

    template: template
    templateHelpers: () ->
      currentPage = @getModel()

      if currentPage
        currentPage = currentPage.toJSON()
        currentPage.encodedTitle = encodeURI(currentPage.title)
      else
        currentPage = {
          title: 'Untitled'
          encodedTitle: 'Untitled'
          authors: []
        }

      downloads = @model.get('downloads')
      pageDownloads = currentPage?.get?('downloads')
      chapter = currentPage.chapter ? currentPage._parent?.get('chapter') ? ''
      downloadable = downloads || pageDownloads

      return {
        currentPage: currentPage
        chapter: chapter
        isBook: @model.isBook()
        pageTitle: currentPage.searchTitle ? currentPage.title
        hasDownloads: if _.isArray downloadable then _.some downloadable, (link) -> link.state != 'missing' else false
        derivable: @isDerivable()
        authenticated: session.get('id')
        editable: @isEditable()
      }

    isEditable: () ->
      if @model.asPage()?.get('loaded') and @model.isDraft()
        edit = @model.asPage()?.get('canPublish')
        if edit isnt undefined and edit.toString().indexOf(session.get('id')) >= 0 and not @model.asPage()?.isDraft()
          @model.set('canChangeLicense', true)
          return true

    isDerivable: () ->
      if @model.asPage()?.get('loaded') and @model.isDraft()
        canEdit = @model.asPage()?.get('canPublish')
        if canEdit isnt undefined and canEdit.toString().indexOf(session.get('id')) < 0
          if @model.get('license')?.code isnt settings.defaultLicense.code
            @model.set('canChangeLicense', false)
          else
            @model.set('canChangeLicense', true)
          return true

    editable:
      '.media-header > .title > h2':
        value: () -> 'title'
        type: 'textinput'

    regions:
      button: '.info .btn'

    events:
      'click .derive .btn': 'derivePage'
      'click .edit .btn' : 'editPage'

    initialize: (options) ->
      super()

      @mediaParent = options.mediaParent
      @mediaBody = options.mediaBody

      @listenTo(@model, 'change:downloads change:buyLink change:title change:active', @render)
      @listenTo(@model, 'change:currentPage change:currentPage.active change:currentPage.loaded', @render)
      @listenTo(@model, 'change:abstract change:currentPage.abstract change:currentPage.chapter', @render)
      @listenTo(session, 'change', @render)
      @listenTo(@model, 'change:currentPage.editable change:currentPage.canPublish', @render)
      @listenTo(@model, 'change:currentPage', @updateTitle)
      @listenTo(router, 'navigate', @updatePageInfo)
      @listenTo(@model, 'change:currentPage.searchTitle', @render)

    onRender: () ->
      #allows user to access 'skiptocontent' and header navigation when navigating from pg to pg in a book
      $(':root').attr("tabindex",0).focus()

      if not @model.asPage()?.get('active') then return

      if window.pageWasChangedWithKeyboard is true then @focusTitle()

      # IE doesn't like it being inside the button. Move it out.
      popoverView = new BookPopoverView
        model: @model
        owner: @$el.find('.info .btn')
      @regions.button.append popoverView
      popoverView.$el.insertAfter(popoverView.$el.parent())

    editPage: () ->
      data = JSON.stringify({id: @model.asPage().get('id')})
      options =
        success: (model) =>
          @model.asPage()?.set('version', 'draft')
          @model.asPage()?.set('editable', true)
          href = linksHelper.getPath 'contents',
            model: @model
            page: @model.getPageNumber()
          router.navigate(href, {trigger: false, analytics: true})
      @model.editOrDeriveContent(options, data)

    derivePage: () ->
      options =
        success: (model) =>
          @model.setPage(@model.getPageNumber(model))
          # Update the url bar path
          href = linksHelper.getPath 'contents',
            model: @model
            page: @model.getPageNumber()
          router.navigate(href, {trigger: false, analytics: true})

      @model.deriveCurrentPage(options)

    updateTitle: () ->
      @pageTitle = @model.get('title')
      if @model.asPage()?
        @pageTitle = "#{@model.get('currentPage').get('title')} - #{@model.get('title')}"

    focusTitle: () ->
      toFocus = $(@$el[0]).find('.media-header .title h2')[0]
      if @model.asPage()?.get('loaded') and toFocus
        toFocus.setAttribute('tabindex', '-1')
        toFocus.focus()
        toFocus.removeAttribute('tabindex')
        window.pageWasChangedWithKeyboard = false
