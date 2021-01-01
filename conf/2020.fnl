(local html (require :html))
(local style (require :conf.style))

(-> [:html {:lang "en"}
     [:head {} [:title {} "FennelConf 2020"]
      (table.unpack style)]
     [:body {}
      [:h1 {} "FennelConf 2020"]
      [:p {} [:b {} "Location:"]
       [:a {:href "https://meet.jit.si/technomancy"} "online"]]
      [:p {} [:b {} "Time:"] "2021-01-02T22:00:00Z (Saturday @ 14:00 US Pacific)"]
      [:p {} "This year FennelConf will simply be an online session "
       "of show-and-tell. Come share what you have been building in "
       "Fennel or just come see what people have to show off! "]
      [:p {} "To sign up, email phil@hagelb.org or contact technomancy on "
       "IRC. Each person can get a slot of 10-15 minutes to show their code. "
       "There is no expectation that presentations should be particularly "
       "polished or fancy. No slides."]
      [:ul {}
       [:li {} "Jeremy Penner - Interactively Programming the Apple ][ "
        "With HoneyLisp"]
       [:li {} "Andrey Orst - Bringing Clojure's seq-mantics into Fennel with Cljlib"]
       [:li {} "Phil Hagelberg -  Structural editing"]
       [:li {} "Ramsey Nasser -  making some noise: integrating Fennel "
        "into the renoise digital audio workstation"]
       [:li {} "Jesse Wertheim - Working the internals - metadata manipulation "
        "and AST serialization"]
       [:li {} "Dan Kurtz - Fireverk"]
       [:li {} "Will Sinatra - toAPK -a fennel"]]
      [:p {} "Yes, FennelConf 2020 will take place in 2021."]
      [:hr {}]
      [:h3 {} "See how much fun we had in: "
       [:a {:href "/2018"} "2018"]
       [:a {:href "/2019"} "2019"]]
      [:hr {}]
      [:p {} "The "
       [:a {:href
            "https://git.sr.ht/~technomancy/fennel/tree/main/CODE-OF-CONDUCT.md"}
        "code of conduct"] " for Fennel applies at FennelConf."]
      [:p {} [:a {:href (.. "https://git.sr.ht/~technomancy/fennel-lang.org/"
                            "tree/main/conf/2020.fnl"
                            )}
              "source"]]]]
    (html)
    (print))
