;; this program generates a syntax file in pandoc format
;; See https://docs.kde.org/stable5/en/applications/katepart/highlight.html
;; requires fennel 0.9.3 or newer

(local fennel (require :fennel))

(fn escape [str]
  (-> str (: :gsub "<" "&lt;") (: :gsub ">" "&gt;")))

(fn classify [name data]
  (if data.define? :defines
      (= "..." name) :keywords
      (name:find "^[^a-z]+$") :operators
      :keywords))

(fn item [entry]
  (string.format "<item>%s</item>" (escape entry)))

(fn syntax-list [section syntax]
  (string.format "    <list name=\"%s\">\n      %s\n    </list>\n"
                 section (table.concat (icollect [name data (pairs syntax)]
                                         (if (= section (classify name data))
                                             (item name)))
                                       "\n      ")))

(fn write []
  (let [head (with-open [f (io.open "fennel-syntax-head.xml")] (f:read "*a"))
        foot (with-open [f (io.open "fennel-syntax-foot.xml")] (f:read "*a"))]
    (print head)
    (print (syntax-list :operators (fennel.syntax)))
    (print (syntax-list :defines (fennel.syntax)))
    (print (syntax-list :keywords (fennel.syntax)))
    (print foot)))

(write)
