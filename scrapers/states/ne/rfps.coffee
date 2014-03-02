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
    
    request.get CONFIG.commodity_url, (err, response, body) ->
      callback err, null if err
      
      jsdom.env
        html: body
        done: (errors, window) ->
          $ = require('jquery')(window)
          
          # Remove unnecessary bits
          $('s, br').remove() # remove the crossed out information
          $('p:empty, p:contains("&nbsp;")').remove() # remove unnecessary html
          $('tr.cell-purch:first').contents().unwrap('tr').wrap('th') # s/tr/th on the header rows
          
          $('.col4full750 tr.cell-purch').each (i, _) ->
            obj = {}
            obj.id = util.trim $(@).find('.cell-purch:nth-child(3) a').text()
            obj.responses_open_at = util.trim $(@).find('.cell-purch:nth-child(2)').text()
            obj.title = util.trim $(@).find('.cell-purch:nth-child(1)').text()
            obj.contact_name = util.trim $(@).find('.cell-purch:nth-child(4)').text()
            obj.html_url = $(@).find('.cell-purch:nth-child(3) a').attr('href')
            obj.html_url = "http://das.nebraska.gov/materiel/" + obj.html_url.substr(6)
            
            request.get obj.html_url, (err, response, body) ->
              jsdom.env
                html: body
                done: (errors, window) ->
                  $ = require('jquery')(window)
                  
                  obj.description = util.trim $('h6:contains("PROJECT DESCRIPTION")').next('p').text()
                  
                  $('.col4full750 tr').each (i, _) ->
                    obj.doc_title = util.trim $(@).find('td:nth-child(1)').text()
                    obj.downloads = new Array()
                    obj.downloads.push $(@).find('td:nth-child(3) a').attr('href')
                  
                  ## If we put them here, the async nature of the GET
                  ## results in an the push running long after the
                  ## other code (most importantly, 'done data') is run
                  #console.log "Added #{obj.title}".green
                  #commodity_data.push obj
                  
                  window.close
            
            ## If we put them here, we get data but the data from
            ## the second page doesn't get added
            console.log "Added #{obj.title}".green
            commodity_data.push obj
          
          window.close
          callback null, commodity_data
  
  # Parses services-rfp.html, returning an array of parsed RFPs
  parseServicesRfpPage = (callback) ->
    services_data = []
    
    request.post CONFIG.services_url, (err, response, body) ->
      callback err, null if err
      
      jsdom.env
        html: body
        done: (errors, window) ->
          $ = require('jquery')(window)
          
          # TODO: parse services page
          
          window.close
          callback null, services_data
  
  # Parses agency-rfp.html, returning an array of parsed RFPs
  parseAgencyRfpPage = (callback) ->
    agency_data = []
    
    request.post CONFIG.agency_url, (err, response, body) ->
      callback err, null if err
      
      jsdom.env
        html: body
        done: (errors, window) ->
          $ = require('jquery')(window)
          
          # TODO: parse agency page
          
          window.close
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
