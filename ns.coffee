FS = require 'fs'
PATH = require 'path'
RL = require 'readline'


class RefactorFile

  legacyRegex: {
    classes: new RegExp('Tx_[^ :]+|t3lib_[^ :]+', 'g')
    classDeclaration: new RegExp('^\s*class Tx_[^ ]+')
    extBaseClasses: new RegExp('Tx_Extbase[^ ]+', 'g')
    fluidClasses: new RegExp('Tx_Fluid[^ ]+', 'g')
    t3libClasses: new RegExp('t3lib_[^ ]+', 'g')
  }

  lineNo: 0
  legacyDataFound: {}
  classDeclarations: {}


  constructor: (@filename) ->
    return if @skip()
    @iface = RL.createInterface(input: FS.createReadStream(@filename), terminal: false)
    @iface.on 'line', @handleLine.bind(@)
#    @iface.on 'close', -> false

  handleLine: (line) ->
    console.log(@filename) if @lineNo == 0
    return unless line

    @lineNo++

    declarations = line.match(@legacyRegex.classDeclaration)
    classes = line.match(@legacyRegex.classes)

    if declarations
      @classDeclarations[@lineNo] = declarations
      console.log "  class declaration [#{@lineNo}]: #{line}"

    if classes
      for className in classes
        if @legacyRegex.extBaseClasses.test(className)
          @legacyDataFound[@lineNo] = [] unless @legacyDataFound[@lineNo]
          console.log "  extbase class     [#{@lineNo}]: #{line}"
        else if @legacyRegex.fluidClasses.test(className)
          console.log "  fluid class       [#{@lineNo}]: #{line}"
        else if @legacyRegex.t3libClasses(className)
          console.log "  t3lib class       [#{@lineNo}]: #{line}"
        else
          console.log "  other class       [#{@lineNo}]: #{line}"

  saveClassName: (className) ->


  skip: ->
    return @filename.indexOf('./Vendor') == 0 or PATH.extname(@filename) != '.php'



# Takes a directory and refactors all files in it recursively
class RefactorDir

  constructor: (@dir) ->
    FS.readdir @dir, @handleFiles.bind(@)

  handleFiles: (err, files) ->
    throw err if err
    if files and files.length
      for file in files
        fullFilename = @dir+'/'+file
        stats = FS.statSync fullFilename
        @handleFile fullFilename, stats

  handleFile: (file, stats) ->
    if stats.isDirectory()
      new RefactorDir file
    else if stats.isFile()
      new RefactorFile file
    else
      console.error 'unkown: '+file


new RefactorDir '.'
