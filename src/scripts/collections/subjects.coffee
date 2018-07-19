define (require) ->
  _ = require('underscore')
  Backbone = require('backbone')
  settings = require('settings')

  archiveport = if settings.cnxarchive.port then ":#{settings.cnxarchive.port}" else ''
  archive = "#{location.protocol}//#{settings.cnxarchive.host}#{archiveport}"

  return new class Subjects extends Backbone.Collection
    url: "#{archive}/extras/subjects"

    list:
      'Arts'                      : '/images/subjects/art.jpg'
      'Business'                  : '/images/subjects/business.jpg'
      'Humanities'                : '/images/subjects/humanities.jpg'
      'Mathematics and Statistics': '/images/subjects/math.jpg'
      'Science and Technology'    : '/images/subjects/science.jpg'
      'Social Sciences'           : '/images/subjects/social_science.jpg'

    initialize: () ->
      @fetch({reset: true})

    parse: (response, options) ->
      subjects = response.subjects

      _.each subjects, (subject) =>
        subject.image = @list[subject.name]

      return subjects
