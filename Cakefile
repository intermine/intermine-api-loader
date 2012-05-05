fs = require "fs" # I/O
cs = require 'coffee-script' # take a guess

# ANSI Terminal colors.
COLORS =
    BOLD:    '\u001b[0;1m'
    RED:     '\u001b[0;31m'
    GREEN:   '\u001b[0;32m'
    BLUE:    '\u001b[0;34m'
    YELLOW:  '\u001b[0;33m'
    DEFAULT: '\u001b[0m'

# --------------------------------------------

# Compile.
task "compile", "compile .coffee to .js", (options) ->

    console.log "#{COLORS.BOLD}Compiling main#{COLORS.DEFAULT}"

    write 'js/loader.js', cs.compile fs.readFileSync('loader.coffee', "utf-8")
        
    # We are done.
    console.log "#{COLORS.GREEN}Done#{COLORS.DEFAULT}"

# Append to existing file.
write = (path, text, mode = "w") ->
    fs.open path, mode, 0o0666, (e, id) ->
        if e then throw new Error(e)
        fs.write id, text, null, "utf8"