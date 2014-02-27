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
      $ = cheerio.load body

      $('.col4full750 .cell-purch .cell-purch:nth-child(3) a').each (i, el) ->
        link = $(this).attr('href')
        id = $(this).text()
        link = link.substr(17)
        link = CONFIG['bid_link_prefix'] + link
        
        obj = {}
        obj['id'] = util.trim id
        obj['html_url'] = link
        
        commodity_data.push obj
    
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
      callback null, [{services: false}]
      return
    
    agency: (callback) ->
      callback null, [{agency: false}]
      return
  
  , (err, results) ->
    if err
      console.log err.read.red
    else
      data = []
      
      data = data.concat(results.commodity)
      data = data.concat(results.services)
      data = data.concat(results.agency)
      
      done data
