(import re)

(var nuit-complex "(?:^[@>\"#])|\n|^$")

; TODO fix this name
(var nuit-invalid-foo "([\u0009\u000B\u000C\u0085\u00A0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000\u0000-\u0008\u000E-\u001F\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF])|(?:([\\s\\S]\uFEFF))")

(var nuit-indent 2)

(def nuit-simple (x)
  (and (isa x 'string)
       (no:re-match nuit-invalid-foo x)
       (no:re-match nuit-complex x)))

(def nuit-string (x i)
  (if (re-match nuit-invalid-foo x)
        (re-replace nuit-invalid-foo (fn args (prn args)))
      (re-match nuit-complex x)
        (string "> " (re-replace* "\n" x (string "\n" (newstring (+ i 2) #\space))))
      x))

#|if (invalid.test(s)) {
      s = s.replace(invalid, function (s, m1, m2) {
        var i = 0
        if (m2) {
          s = m2[0]
          i = 1
        }
        return s + "\\u(" + (m2 || m1).charCodeAt(i).toString(16).toUpperCase() + ")"
      })
      s = "\" " + s.replace(/\n/g, "\\\n" + spaces(i + 2))|#

(def nuit-serialize1 (x i)
  (repeat i (pr " "))
  (if (isa x 'cons)
      (do (repeat i (pr " "))
          (pr "@")
          (when (nuit-simple car.x)
            (pr car.x)
            (zap cdr x)
            (when (nuit-simple car.x)
              (pr " ")
              (pr car.x)
              (zap cdr x)))
          (pr "\n")
          (each x x
            (nuit-serialize1 x (+ i nuit-indent))
            (pr "\n")))
      (pr (nuit-string x i))))

(def nuit-serialize (x)
  (tostring:awhenlet (x . rest) x
    (nuit-serialize1 x 0)
    (when rest
      (pr "\n")
      (self rest))))

; console.log(require("./lib/nuit.serialize.js").serialize("F\u0000OOBAR\uFEFF\nbarqux\nnou"))
