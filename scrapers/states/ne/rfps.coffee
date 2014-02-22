# Require the necessary modules.
request = require 'request'
cheerio = require 'cheerio'
async = require 'async'
_ = require 'underscore'
require 'colors'

# We'll export one function, that takes two parameters: an options hash,
# and a callback that must be executed once we're done scraping.
module.exports = (opts, done) ->

  # Set up an empty array for our RFPs.
  rfps = []
