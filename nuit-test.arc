(import nuit-parse)

;; TODO: generic utility
(mac assert (x y)
  (w/uniq (u v)
    `(let ,u (on-err (fn (,u)
                       (string "error: " (details ,u)))
                     (fn () ,x))
       (let ,v (on-err (fn (,u)
                         (string "error: " (details ,u)))
                       (fn () ,y))
         (unless (iso ,u ,v)
           (prn)
           (pr "failed assertion\n  expected:  ")
           (write ,u)
           (pr "\n  but got:   ")
           (write ,v)
           (prn))))))


(assert (err "invalid character \t
  \tfoobar  (line 1, column 1)
  ^")
  (nuit-parse "\tfoobar"))

(assert (err "expected an indent of 0 but got 1
   yes  (line 4, column 1)
  ^")
  (nuit-parse "
@foobar
  @quxnou
 yes
"))

(assert (err "expected an indent of 1 but got 0
  @foobar  (line 6, column 1)
  ^")
  (nuit-parse "
 @foobar
   @quxnou
   yes

@foobar
  @quxnou
  yes
"))

(assert (err "expected an indent of 2 but got 3
     @foobar  (line 6, column 3)
    ^")
  (nuit-parse "
  @foobar
    @quxnou
    yes

   @foobar
    @quxnou
    yes
"))

(assert (err "expected an indent of 0 but got 1
   questionable  (line 4, column 1)
  ^")
  (nuit-parse "
` foo bar qux
    yes maybe no
 questionable"))

(assert (err "expected any of [newline \\ s n u] but got b
  \" foo\\bar  (line 2, column 7)
        ^")
  (nuit-parse "
\" foo\\bar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "expected ( but got A
  \" foo\\uAB01ar  (line 2, column 8)
         ^")
  (nuit-parse "
\" foo\\uAB01ar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "expected ( but got newline
  \" foo\\u  (line 2, column 8)
         ^")
  (nuit-parse "
\" foo\\u
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "expected hexadecimal but got )
  \" foo\\u()  (line 2, column 9)
          ^")
  (nuit-parse "
\" foo\\u()
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "expected space or ) but got newline
  \" foo\\u(AB01 FA1  (line 2, column 17)
                  ^")
  (nuit-parse "
\" foo\\u(AB01 FA1
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "expected hexadecimal but got U
  \" foo\\u(AB01 FA1U  (line 2, column 17)
                  ^")
  (nuit-parse "
\" foo\\u(AB01 FA1U
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "expected hexadecimal but got U
  \" foo\\u(AB01 U)ar  (line 2, column 14)
               ^")
  (nuit-parse "
\" foo\\u(AB01 U)ar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert (err "invalid character \u0000
  foo\u0000bar  (line 1, column 4)
     ^")
  (nuit-parse "foo\u0000bar"))

(assert (err "invalid character \u0000
  \u0000foobar  (line 1, column 1)
  ^")
  (nuit-parse "\u0000foobar"))

(assert (err "invalid character \uFEFF
  f\uFEFFoobar  (line 1, column 2)
   ^")
  (nuit-parse "f\uFEFFoobar"))

(assert (err "integer->char: expects argument of type <exact integer in [0,#x10FFFF], not in [#xD800,#xDFFF]>; given 55296")
  (nuit-parse "
\" foo\\u(D800)bar"))

(assert (err "integer->char: expects argument of type <exact integer in [0,#x10FFFF], not in [#xD800,#xDFFF]>; given 57343")
  (nuit-parse "
\" foo\\u(DFFF)bar"))

(assert (err "expected space or newline but got f
  `foobar  (line 2, column 2)
   ^")
  (nuit-parse "
`foobar
"))

(assert (err "expected an indent of 0 but got 1
   foobar  (line 3, column 1)
  ^")
  (nuit-parse "
`
 foobar
   quxcorge
 nou yes
 maybe sometimes
"))

(assert (err "expected an indent of 0 but got 5
       foobar  (line 4, column 5)
      ^")
  (nuit-parse "
@foo
    \"
     foobar
       quxcorge
     nou yes
     maybe sometimes
"))

(assert (err "expected any of [newline \\ s n u] but got b
  \" foobar\\b  (line 1, column 10)
           ^")
  (nuit-parse "\" foobar\\b"))

(assert (err "expected hexadecimal but got space
    qux\\u(   20      20AC   )corge  (line 3, column 9)
          ^")
  (nuit-parse "
\" foo\\\\bar
  qux\\u(   20      20AC   )corge
  nou yes
  maybe sometimes
"))

(assert (err "expected hexadecimal but got space
    qux\\u(20  20AC)corge  (line 3, column 12)
             ^")
  (nuit-parse "
\" foo\\\\bar
  qux\\u(20  20AC)corge
  nou yes
  maybe sometimes
"))




(assert '("\\$foobar")
  (nuit-parse "\\$foobar"))

(assert '("yestoo")
  (nuit-parse "
# foobar
 quxcorge
   nou yes
 maybe sometimes
   oneday
yestoo
"))

(assert '("foobar")
  (nuit-parse " foobar"))

(assert '(("foobar"))
  (nuit-parse " @foobar"))

(assert '("foo힙bar")
  (nuit-parse "
\" foo\\u(D799)bar"))

(assert '("foo\uE000bar")
  (nuit-parse "
\" foo\\u(E000)bar"))

(assert '("foobar")
  (nuit-parse "\uFEFFfoobar"))

(assert '(("foo" ("bar" "10")
            ("qux" "nou"))
          ("yes"))
  (nuit-parse "
@foo @bar 10
  @qux nou
@yes"))

(assert '(("foo" ("bar" "10")
            ("qux" "nou"))
          ("yes"))
  (nuit-parse "
@foo @bar 10
     @qux nou
@yes"))

(assert '(("foo" ("bar" "10"
                   ("qux" "nou")))
          ("yes"))
  (nuit-parse "
@foo @bar 10
      @qux nou
@yes"))

(assert '(("foo")
          ("yes"))
  (nuit-parse "
@foo #@bar 10
      @qux nou
@yes"))

(assert '(("foo" "")
          ("yes"))
  (nuit-parse "
@foo `
@yes"))

(assert '(("foo")
          ("yes"))
  (nuit-parse "
@foo
@yes"))

(assert '(("foo" "bar" "qux" "corge"))
  (nuit-parse "@foo bar\n  qux\n   \n  corge"))

(assert '(("foo" "bar" "qux" "corge"))
  (nuit-parse "@foo bar\n  qux\n  \n  corge"))

(assert '(("foo" "bar" "qux" "corge"))
  (nuit-parse "@foo bar\n  qux\n \n  corge"))

(assert '(("foo" "bar" "qux" "corge"))
  (nuit-parse "@foo bar\n  qux\n\n  corge"))

(assert '("foobar")
  (nuit-parse "       \nfoobar"))

(assert '("foobar" "quxcorge")
  (nuit-parse "\nfoobar  \nquxcorge"))

(assert '("foobar")
  (nuit-parse "foobar"))

(assert '("\\\"foobar")
  (nuit-parse "\\\"foobar"))

(assert '(("foo" "bar" ("testing") "qux \"\"\" yes" "corge 123" "nou@ yes")
          ("another" "one" "inb4 this#" "next thread"
            ("nested\\" "lists are cool"
              ("yes" "indeed")
              ("no" "maybe"))
            ("oh yes" "oh my")
            ("oh yes" "oh my")))
  (nuit-parse "
@foo bar
  @testing
  qux \"\"\" yes

  corge 123
  nou@ yes

@another one
  inb4 this#

  next thread
  @nested\\
    lists are cool

    @yes indeed
    @no maybe
  @ oh yes

   oh my
  @ oh yes
   oh my
"))

(assert '(("foo" "bar" ("testing") "qux \"\"\" yes" "corge 123" "nou@ yes")
          ("another" "one" "inb4 this#" "next thread"
            ("nested\\" "lists are cool"
              ("yes" "indeed")
              ("no" "maybe"))
            ("oh yes" "oh my")
            ("oh yes" "oh my")))
  (nuit-parse "

    @foo bar
      @testing
      qux \"\"\" yes

      corge 123
      nou@ yes

    @another one
      inb4 this#

      next thread
      @nested\\
        lists are cool

        @yes indeed
        @no maybe
      @ oh yes

       oh my
      @ oh yes
       oh my

"))

(assert '(() ("foobar" "qux"))
  (nuit-parse "
@
@
 foobar
 qux"))

(assert '("foo bar qux\nyes maybe no\nquestionable")
  (nuit-parse "
` foo bar qux
  yes maybe no
  questionable"))

(assert '(("foobar" "foo bar qux\n  yes maybe no\n  questionable"))
  (nuit-parse "
@foobar
  ` foo bar qux
      yes maybe no
      questionable"))

(assert '("foo bar qux\n  yes maybe no\n  questionable")
  (nuit-parse "
` foo bar qux
    yes maybe no
    questionable"))

(assert '("yestoo")
  (nuit-parse "
# foobar
  quxcorge
  nou yes
  maybe sometimes
yestoo
"))

(assert '("yestoo")
  (nuit-parse "
#foobar
 quxcorge
 nou yes
 maybe sometimes
yestoo
"))

(assert '()
  (nuit-parse "
# foobar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert '(("another" "one" "inb4 this#" "next thread"
            ("oh yes")
            ("oh yes" "oh my")))
  (nuit-parse "
#@foo bar
  @testing
  qux \"\"\" yes
  corge 123
  nou@ yes
@another one
  inb4 this#
  next thread
  #@nested\\
    lists are cool
    @yes indeed
    @no maybe
  @ oh yes
   #oh my
  @ oh yes
   oh my
"))

(assert '("foobar\n\nquxcorge\n\nnou yes\n\nmaybe sometimes")
  (nuit-parse "
` foobar

  quxcorge

  nou yes

  maybe sometimes
"))

(assert '("foobar\n\nquxcorge\n\nnou yes\n\nmaybe sometimes")
  (nuit-parse "
\" foobar

  quxcorge

  nou yes

  maybe sometimes
"))

(assert '("foobar\n\n\nquxcorge\n\nnou yes\n\n\nmaybe sometimes")
  (nuit-parse "
\" foobar


  quxcorge

  nou yes


  maybe sometimes
"))

(assert '("foobar\n\n\n\nquxcorge\n\nnou yes\n\n\n\nmaybe sometimes")
  (nuit-parse "
\" foobar



  quxcorge

  nou yes



  maybe sometimes
"))

(assert '("foobar quxcorge nou yes maybe sometimes")
  (nuit-parse "
\" foobar
  quxcorge
  nou yes
  maybe sometimes
"))

(assert '("foobar\nquxcorge\nnou yes\nmaybe sometimes")
  (nuit-parse "
\" foobar\\
  quxcorge\\
  nou yes\\
  maybe sometimes\\
"))

(assert '("foobar\nquxcorge\nnou yes\nmaybe sometimes" "mooooooooooo")
  (nuit-parse "
\" foobar\\
  quxcorge\\
  nou yes\\
  maybe sometimes
mooooooooooo
"))

(assert '("foobar\nquxcorge\nnou yes\nmaybe sometimes" "mooooooooooo")
  (nuit-parse "
\" foobar\\
  quxcorge\\
  nou yes\\
  maybe sometimes\\
mooooooooooo
"))

(assert '("foo\\bar qux €corge nou yes maybe sometimes")
  (nuit-parse "
\" foo\\\\bar
  qux\\u(20 20AC)corge
  nou yes
  maybe sometimes
"))

(assert '("foobar\nquxcorge\nnou yes\nmaybe sometimes")
  (nuit-parse "\n\" foobar\\  \n  quxcorge\\\n  nou yes\\\n  maybe sometimes\n"))

(assert '("" "foobar" "quxcorge" "nou yes" "maybe sometimes")
  (nuit-parse "
`
foobar
quxcorge
nou yes
maybe sometimes
"))

(assert '("foobar\n  quxcorge\nnou yes\nmaybe sometimes")
  (nuit-parse "
`
  foobar
    quxcorge
  nou yes
  maybe sometimes
"))

(assert '(("foo" "foobar\nquxcorge\nnou yes\nmaybe sometimes"))
  (nuit-parse "
@foo
    `
      foobar
      quxcorge
      nou yes
      maybe sometimes
"))

(assert '(("foo" "" "foobar" "quxcorge" "nou yes" "maybe sometimes"))
  (nuit-parse "
@foo
    `
    foobar
    quxcorge
    nou yes
    maybe sometimes
"))

(assert '(("foo" "foobar   quxcorge nou yes maybe sometimes"))
  (nuit-parse "
@foo
    \"
      foobar
        quxcorge
      nou yes
      maybe sometimes
"))

(assert '(("foo" "" "foobar" "quxcorge" "nou yes" "maybe sometimes"))
  (nuit-parse "
@foo
    \"
    foobar
    quxcorge
    nou yes
    maybe sometimes
"))

(assert '("foobar\\s")
  (nuit-parse "` foobar\\s"))

(assert '("foobar\\n")
  (nuit-parse "` foobar\\n"))

(assert '("foobar\\n\nquxcorge")
  (nuit-parse "
` foobar\\n
  quxcorge
"))

(assert '("foobar ")
  (nuit-parse "\" foobar\\s"))

(assert '("foobar\n")
  (nuit-parse "\" foobar\\n"))

(assert '("foobar\n quxcorge")
  (nuit-parse "
\" foobar\\n
  quxcorge
"))
