define (require) ->
  EditableView = require('cs!helpers/backbone/views/editable')

  return class FooterTabView extends EditableView
    templateHelpers: () ->
      if @media is 'page'
        model = @model.get('currentPage')?.toJSON()
      else
        @media = 'book'
        model = @model.toJSON()

      return model or {}

    events:
      'click > .book-page-toggle > .btn:not(.active)': 'toggleMedia'

    initialize: () ->
      super()
      @listenTo(@model, 'changePage', @render)

    toggleMedia: (e) ->
      @media = $(e.currentTarget).data('media')
      @render()
