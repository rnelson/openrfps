request = require 'request'
cheerio = require 'cheerio'
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
    
    request.post CONFIG['commodity_url'], (err, response, body) ->
      obj = {}
      $ = cheerio.load body
      
      # remove unnecessary bits
      $('s, br').remove() # remove the crossed out information
      $('p:empty, p:contains("&nbsp;")').remove() # remove unnecessary html
      
      # TODO: make this work
      #$('.col4full750 .cell-purch').each (i, el) ->
        # id, html_url
        #obj['id'] = $(this).find('.cell-purch:nth-child(3) a').text()
        #obj['html_url'] = CONFIG['bid_link_prefix'] + $(this).find('.cell-purch:nth-child(3) a').attr('href').substr(17)
      
      commodity_data.push obj
    
    # Done with commodity data; send the data or an error back
    callback err, null if err
    callback null, commodity_data
  
  
  # main() - parses all three pages at once, combines the results,
  # and sends the results back to OpenRFPs to generate the JSON
  # output file
  async.parallel
    commodity: (callback) ->
      parseCommodityRfpPage (err, data) ->
        callback err, data
    
    services: (callback) ->
      callback null, null #[{services: false}]
      return
    
    agency: (callback) ->
      callback null, null #[{agency: false}]
      return
  
  , (err, results) ->
    if err
      console.log err.read.red
    else
      data = []
      
      data = data.concat(results.commodity) if results.commodity
      data = data.concat(results.services) if results.services
      data = data.concat(results.agency) if results.agency
      
      done data
