fs      = require 'fs'
path    = require 'path'

env     = require('jsdom').env
jquery  = require 'jquery'
mkdirp  = require 'mkdirp'
request = require 'request'
_       = require 'underscore'

HOST = 'https://hapsis.ghost.io'

# MAIN

# TODO: when a Ghost public API comes out, authenticate, grab JSON and download
fs.readFile path.join(__dirname, 'GhostData.json'), (readError, data) ->
  if readError?
    console.error "ERROR GRABBING GhostData.json: #{readError}"
  else
    backupContent JSON.parse data
  return

# /MAIN
# BACKUP HELPERS

backupAsset = (assetPath, callback) ->
  assetUrl = "#{HOST}#{assetPath}"
  console.log "BACKING UP ASSET: #{assetPath}"

  fullPath = path.join __dirname, assetPath
  dirPath = fullPath.split '/'
  dirPath.pop()
  dirPath = dirPath.join '/'
  mkdirp dirPath, (mkdirError) ->
    if mkdirError?
      console.error "ERROR CREATING PATH #{dirPath}: #{mkdirError}"
    else
      r = request(assetUrl).pipe(fs.createWriteStream(fullPath), end: false)

      r.on 'error', (error) ->
        console.error "ERROR GRABBING ASSET: #{error}"
        callback()

      r.on 'end', ->
        callback()
  return

backupImages = (html) ->
  env html, (errors, window) ->
    if errors?
      console.error "ERROR LOADING POST HTML: #{errors}"
    else
      $ = jquery window
      $images = $('img')
      imageIndex = 0
      backupImage = ->
        return if imageIndex is $images.length
        $img = $images.eq imageIndex
        imageIndex++
        backupAsset $img.attr('src'), backupImage
        return
      backupImage()
    return
  return

backupContent = (ghostData) ->
  posts = ghostData.data.posts
  _.each posts, (post) ->
    if post.html?
      backupImages post.html
    return
  return

# /BACKUP HELPERS
