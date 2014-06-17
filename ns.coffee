FS = require 'fs'
PATH = require 'path'
RL = require 'readline'


class RefactorFile

  legacyRegex: {
    classes: new RegExp('Tx_[^ :(\'"]+|t3lib_[^ :(\'"]+', 'g')
    classDeclaration: new RegExp('^\s*class Tx_[^ ]+')
    extBaseClasses: new RegExp('Tx_Extbase[^ :(\'"]+', 'g')
    fluidClasses: new RegExp('Tx_Fluid[^ :(\'"]+', 'g')
    t3libClasses: new RegExp('t3lib_[^ :(\'"]+', 'g')
  }

  lineNo: 0
  classDeclarations: {}


  constructor: (@filename) ->
    return if @skip()
    @iface = RL.createInterface(input: FS.createReadStream(@filename), terminal: false)
    @iface.on 'line', @handleLine.bind(@)
    @iface.on 'close', @summarize.bind(@)


  summarize: ->
    return unless @legacyDataFound
    console.log @filename

    hasClassDeclaration = if @classDeclarations.length then 'yes' else 'no'
    console.log "  has a legacy class declaration? #{hasClassDeclaration}"

    for lineNo, info of @legacyDataFound
      for type, className of info
        console.log "  #{type} class [#{lineNo}]: #{className}"


  handleLine: (line) ->
    return unless line

    @lineNo++

    declarations = line.match(@legacyRegex.classDeclaration)
    classes = line.match(@legacyRegex.classes)

    if declarations
      @classDeclarations[@lineNo] = declarations

    if classes
      for className in classes
        continue if @saveClassName(className, @legacyRegex.extBaseClasses, 'extbase')
        continue if @saveClassName(className, @legacyRegex.fluidClasses, 'fluid')
        continue if @saveClassName(className, @legacyRegex.t3libClasses, 't3lib')
        @saveClassName(className, '', 'other')

  saveClassName: (className, regex, type) ->
    if type ==  'other' or regex.test(className)
      @legacyDataFound = {} unless @legacyDataFound
      @legacyDataFound[@filename+' '+@lineNo] = {} unless @legacyDataFound[@filename+' '+@lineNo]
      @legacyDataFound[@filename+' '+@lineNo][type] = [] unless @legacyDataFound[@filename+' '+@lineNo][type]
      @legacyDataFound[@filename+' '+@lineNo][type].push className
      return true
    return false


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
