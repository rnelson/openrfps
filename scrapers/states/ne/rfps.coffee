request = require 'request'
jsdom = require 'jsdom'
async = require 'async'
_ = require 'underscore'
YAML = require 'libyaml'
util = require __dirname + '/util'
require 'colors'

module.exports = (opts, done) ->
  # Read in config.yml to grab the URLs we need to parse
  CONFIG = YAML.readFileSync(__dirname + '/config.yml')[0]
  
  # Parses commodity-itb.html, returning an array of parsed RFPs
  parseCommodityRfpPage = (callback) ->
    commodity_data = []
    err = null
    
    request.post CONFIG.commodity_url, (err, response, body) ->
      jsdom.env
        html: body
        done: (errors, window) ->
          $ = require('jquery')(window)
          
          # Remove unnecessary bits (TODO: these don't work, or at least $ isn't saving the result?)
          $('s, br').remove() # remove the crossed out information
          $('p:empty, p:contains("&nbsp;")').remove() # remove unnecessary html
          
          # TODO: finish this
          $('.col4full750 .cell-purch').each (i, _) ->
            obj = {}
            obj.id = $(@).find('.cell-purch:nth-child(3) a').text()
            
            console.log "Added #{obj.id}".green
            commodity_data.push obj
          
          # Done with commodity data; send the data or an error back
          callback err, null if err
          callback null, commodity_data
  
  # Parses services-rfp.html, returning an array of parsed RFPs
  parseServicesRfpPage = (callback) ->
    services_data = []
    err = null
    
    request.post CONFIG.services_url, (err, response, body) ->
      jsdom.env
        html: body
        done: (errors, window) ->
          $ = require('jquery')(window)
          
          # TODO: parse services page
          
          # Done with commodity data; send the data or an error back
          callback err, null if err
          callback null, services_data
  
  # Parses agency-rfp.html, returning an array of parsed RFPs
  parseAgencyRfpPage = (callback) ->
    agency_data = []
    err = null
    
    request.post CONFIG.agency_url, (err, response, body) ->
      jsdom.env
        html: body
        done: (errors, window) ->
          $ = require('jquery')(window)
          
          # TODO: parse agency page
          
          # Done with commodity data; send the data or an error back
          callback err, null if err
          callback null, agency_data 
  
  
  # main() - parses all three pages at once, combines the results,
  # and sends the results back to OpenRFPs to generate the JSON
  # output file
  async.parallel
    commodity: (callback) ->
      parseCommodityRfpPage (err, data) ->
        callback err, data
    
    services: (callback) ->
      parseServicesRfpPage (err, data) ->
        callback err, data
    
    agency: (callback) ->
      parseAgencyRfpPage (err, data) ->
        callback err, data
  
  , (err, results) ->
    if err
      console.log err.read.red
    else
      data = []
      
      data = data.concat(results.commodity) if results.commodity
      data = data.concat(results.services) if results.services
      data = data.concat(results.agency) if results.agency
      
      done data
