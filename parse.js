// TODO line/columns in error messages, probably use "lib/util/buffer"
define([], function () {
  "use strict";

  // TODO: not specific to Nuit
  function iterator(a) {
    var i = 0
    return {
      peek: function () {
        return a[i]
      },
      read: function () {
        return a[i++]
      },
      has: function () {
        return i < a.length
      }
    }
  }

  function invalid(s) {
    // TODO JavaScript doesn't allow you to use these Unicode code points in strings
    // \u1FFFE
    // \u1FFFF
    // \u10FFFE
    // \u10FFFF
    return /[\u0009\u000B\u000C\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000\u0000-\u0008\u000E-\u001F\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF\uFEFF\uD800-\uDFFF]/.exec(s)
  }

  function charToHex(s) {
    // TODO use codePointAt
    return s.charCodeAt(0).toString(16).toUpperCase()
  }

  function print(s) {
    if (s == null) {
      return "<EOF>"
    } else if (s === " ") {
      return "<space>"
    } else if (s === "\n") {
      return "<newline>"
    } else {
      if (invalid(s)) {
        return "\\u(" + charToHex(s) + ")"
      } else {
        return s
      }
    }
  }

  // TODO make this lazy, so it goes through the string one line at a time
  function normalize(s) {
    s = s.replace(/^\uFEFF/g, "")             // Get rid of Unicode byte order mark
    s = s.replace(/ +(?=\r\n|[\n\r]|$)/g, "") // Get rid of whitespace at the end of the line
    s = s.replace(/^(?:\r\n|[\n\r])+/g, "")   // Get rid of newlines at the start of the string
    s = s.replace(/(?:\r\n|[\n\r])+$/g, "")   // Get rid of newlines at the end of the string

    var a = invalid(s)
    if (a !== null) {
      throw new Error("invalid Unicode character " + print(a[0]))
    }

    // For each line
    return iterator(s.split(/(?:\r\n|[\n\r])/g).map(function (s) {
      // Split the line into indent and everything after indent
      var a = /^( *)(.*)$/.exec(s)
      return {
        indent: a[1].length,
        text:   a[2]
      }
    }))
  }

  function parseString(o, x, transform) {
    var r = []
    if (x.text[1] === " ") {
      r.push(x.text.slice(2))
      r.push("\n")
    } else if (x.text.length !== 1) {
      throw new Error("expected <space> or <newline> after " + x.text[0] + " but got " + print(x.text[1]))
    }

    // Adds lines that are either empty or a greater indent
    var index = x.indent + 2
    while (o.has()) {
      var y = o.peek()
      if (y.text === "") {
        o.read()
        r.push("\n")
      } else if (y.indent >= index) {
        o.read()
        r.push(new Array(y.indent - index + 1).join(" ") + y.text)
        r.push("\n")
      } else {
        break
      }
    }

    // Get rid of trailing newlines and transform it
    return transform(r.join("").replace(/\n+$/g, ""))
  }

  function charsToUnicode(x) {
    var i = parseInt(x, 16)
      , s = String.fromCharCode(i) // TODO use String.fromCodePoint instead
    // U+D800 - U+DFFF
    if (i >= 55296 && i <= 57343) {
      throw new Error(print(s) + " is invalid in Unicode code point escapes")
    }
    return s
  }

  // TODO U+D800 - U+DFFF should be invalid
  function parseUnicodeEscape(o) {
    var c = o.read()
    if (c === "(") {
      var r = []
      while (true) {
        var a = []
        while (o.has()) {
          if (/[0-9a-fA-F]/.test(o.peek())) {
            a.push(o.read())
          } else {
            break
          }
        }
        c = o.read() // TODO should probably check o.has()
        if (a.length === 0) {
          throw new Error("expected any of [0123456789abcdefABCDEF] but got "  + print(c))
        } else if (c === " ") {
          r.push(charsToUnicode(a.join("")))
          a = []
        } else if (c === ")") {
          r.push(charsToUnicode(a.join("")))
          break
        } else {
          throw new Error("expected ) but got " + print(c))
        }
      }
      return r.join("")
    } else {
      throw new Error("expected \\u( but got \\u" + print(c))
    }
  }

  function parseQuoteString(o) {
    var r = []

    while (o.has()) {
      var c = o.read()
      if (c === "\\") {
        // Trailing \ at the end of the string is ignored
        if (o.has()) {
          c = o.read()
          if (c === "\n" || c === "\\") {
            r.push(c)
          } else if (c === "s") {
            r.push(" ")
          } else if (c === "n") {
            r.push("\n")
          } else if (c === "u") {
            r.push(parseUnicodeEscape(o))
          } else {
            throw new Error("expected any of \\<newline> \\\\ \\s \\n \\u but got \\" + print(c))
          }
        }
      } else if (c === "\n") {
        var a = [c]
        while (o.has() && o.peek() === "\n") {
          a.push(o.read())
        }
        // Single newlines are converted to a space
        if (a.length === 1) {
          r.push(" ")
        } else {
          r.push(a.join(""))
        }
      } else {
        r.push(c)
      }
    }

    return r.join("")
  }

  function parse(o, x) {
    switch (x.text[0]) {
    case "#":
      while (o.has()) {
        var y = o.peek()
        // Ignore empty lines and lines with a greater indent than #
        if (y.text === "" || y.indent > x.indent) {
          o.read()
        } else {
          break
        }
      }
      return null
    case "@":
      var a = /^@([^ ]*)( *)(.*)$/.exec(x.text)
      var r = []
      console.log(a)
      if (a[1] !== "") {
        r.push(a[1])
      }
      if (a[3] !== "") {
        var y = parse(o, {
          indent: x.indent + 1 + a[1].length + a[2].length,
          text:   a[3]
        })
        if (y !== null) {
          r.push(y)
        }
      }
      while (o.has() && o.peek().text === "") {
        o.read()
      }
      // Include all lines that are the same indent as the second line
      if (o.has() && o.peek().indent > x.indent) {
        parseList(r, o)
      }
      return r
    case ">":
      return parseString(o, x, function (x) {
        return x
      })
    case "\"":
      return parseString(o, x, function (x) {
        return parseQuoteString(iterator(x))
      })
    default:
      return x.text
    }
  }
  
  function parseList(r, o, error) {
    var indent = o.peek().indent
    while (o.has()) {
      var x = o.peek()
      if (x.indent === indent) {
        var y = parse(o, o.read())
        if (y !== null) {
          r.push(y)
        }
      // TODO a little hacky
      } else if (error || x.indent > indent) {
        throw new Error("expected an indent of " + indent + " but got " + x.indent)
      } else {
        break
      }
    }
  }

  return function (s) {
    var o = normalize(s)
      , r = []
    if (o.has()) {
      parseList(r, o, true)
    }
    return r
  }
})