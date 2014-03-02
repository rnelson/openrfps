request = require 'request'
srequest = require 'request-sync'
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
            obj.commodity = obj.title
            obj.contact_name = util.trim $(@).find('.cell-purch:nth-child(4)').text()
            obj.html_url = $(@).find('.cell-purch:nth-child(3) a').attr('href')
            obj.html_url = "http://das.nebraska.gov/materiel/" + obj.html_url.substr(6)
            
            details = srequest(
              method: 'GET'
              uri: obj.html_url
            )
            jsdom.env
              html: details.body
              done: (errors, window) ->
                $ = require('jquery')(window)
                
                obj.description = util.trim $('h6:contains("PROJECT DESCRIPTION")').next('p').text()
                obj.created_at = $('tr:contains("Invitation to Bid")').children('td:nth-child(2)').text()
                obj.responses_open_at = $('tr:contains("ITB Bid Opening Date")').children('td:nth-child(2)').text()

                $('tr:nth-child(3):contains("PDF")').each (i, _) ->
                  obj.downloads = new Array()
                  obj.downloads.push "http://das.nebraska.gov/materiel/purchasing/" + $(@).find('td:nth-child(3) a').attr('href')
              
                window.close

            # Done scraping; add this result and move on to the next
            console.log "Successfully downloaded #{obj.title}".green
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

          # Remove unnecessary bits
          $('s, br').remove() # remove the crossed out information
          $('p:empty, p:contains("&nbsp;")').remove() # remove unnecessary html
          #$('tr:first').contents().unwrap('tr').wrap('th') # s/tr/th on the header rows

          $('section .col4full750:nth-child(4) tr').not('.cell-head').each (i, _) ->
            obj = {}
            obj.id = $(@).find('td:nth-child(5)').text()
            obj.html_url = $(@).find('td:nth-child(5) a').attr('href')
            obj.html_url = "http://das.nebraska.gov/materiel/" + obj.html_url.substr(6)
            
            services_data.push obj
          
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
