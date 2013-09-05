define (require) ->
  $ = require('jquery')
  _ = require('underscore')
  BaseView = require('cs!helpers/backbone/views/base')
  MailPopoverView = require('cs!./popovers/mail/mail')
  template = require('hbs!./title-template')
  require('less!./title')

  return class MediaTitleView extends BaseView
    template: (data) ->
      data.share =
        url: window.location.href.split('#')[0] # Get the current URL without a hash string
        source: data.source or data.currentPage.source or 'OpenStax College'
        summary: data.summary or data.currentPage.summary or 'An OpenStax College book.'
        title: data.title or data.currentPage.title
        image: data.image or data.currentPage.image or "#{window.location.host}/images/logo.png"

      # Encode all of the shared values for a URI
      _.each data.share, (value, key, list) ->
        list[key] = encodeURI(value)

      return template(data)

    onRender: () ->
      $share = @$el.find('.share')
      @attachPopover new MailPopoverView({owner: $share.find('.mail')})
