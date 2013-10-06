# Representation of individual nodes in a book's tree (table of contents).
# A Node can represent both a tree (subcollection), or leaf (page).
# Page Nodes also are used to cache a page's content once loaded.

define (require) ->
  $ = require('jquery')
  _ = require('underscore')
  Backbone = require('backbone')
  settings = require('cs!settings')
  require('backbone-associations')

  CONTENT_URI = "#{location.protocol}//#{settings.cnxarchive.host}:#{settings.cnxarchive.port}/contents"

  return class Node extends Backbone.AssociatedModel
    url: () -> "#{CONTENT_URI}/#{@id}"
    defaults:
      authors: []

    parse: (response, options) ->
      # Don't overwrite the title from the book's table of contents
      if @get('title')
        delete response.title

      # If this model has no content field (like a book), then don't try to process it.
      if not response.content then return response

      # jQuery can not build a jQuery object with <head> or <body> tags,
      # and will instead move all elements in them up one level.
      # Use a regex to extract everything in the body and put it into a div instead.
      $body = $('<div>' + response.content.replace(/^[\s\S]*<body.*?>|<\/body>[\s\S]*$/g, '') + '</div>')
      $body.children('.title').eq(0).remove()
      response.content = $body.html()

      return response

    relations: [{
      type: Backbone.Many
      key: 'contents'
      relatedModel: Node
    }]
