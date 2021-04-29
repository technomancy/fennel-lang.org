.DEFAULT_GOAL := build

TAGS := $(shell git --git-dir=./fennel/.git tag -l | grep '^[0-9]' | grep -v - | tac)
TAGDIRS := main $(foreach tag, $(TAGS), v${tag})

# which fennel/$.md files build a tag index
TAGSOURCES := changelog reference api

HTML := tutorial.html api.html reference.html lua-primer.html changelog.html \
	setup.html rationale.html from-clojure.html
LUA := fennelview.lua

# This requires pandoc 2.0+
PANDOC ?= pandoc --syntax-definition fennel-syntax.xml \
	-H head.html -A foot.html -T "Fennel" \
	--lua-filter=promote-h1-to-title.lua

fennel/fennel: ; make -C fennel fennel

index.html: main.fnl sample.html fennel/fennel
	fennel/fennel main.fnl $(TAGDIRS) > index.html
%.lua: fennel/%.fnl fennel/fennel ; fennel/fennel --compile $< > $@

fennelview.lua: fennel/fennel fennel/src/fennel/view.fnl
	fennel/fennel --compile fennel/src/fennel/view.fnl > $@

%.html: fennel/%.md ; $(PANDOC) --toc -o $@ $^

# Special overrides; for instance rationale does not need a TOC
rationale.html: fennel/rationale.md ; $(PANDOC) -o $@ $^

# TODO: for now all main and tags are generated the same;
# there might be time, when we have "generations" of fennel

%/tag-intro.md: fennel/fennel ; fennel/fennel tag-intro.fnl $@ > $@
%/repl.md: repl.md ; cp $^ $@
%/init.lua: init.lua ; cp $^ $@
%/repl.fnl: repl.fnl ; cp $^ $@

v%/fennel:
	git clone --branch $* fennel $@
	make -C $(@D) fennel
	touch setup.md # not all tags have this

main/fennel:
	git clone --branch main fennel $@
	make -C $(@D) fennel

v%/index.html: v%/tag-intro.md v%/repl.md $(foreach md, $(TAGSOURCES), \
		v%/fennel/${md}.md)
	$(PANDOC) -o $@ $^

main/index.html: main/tag-intro.md main/repl.md \
		$(foreach md, $(TAGSOURCES), main/fennel/${md}.md)
	$(PANDOC) -o $@ $^ && rm main/tag-intro.md

tagdirs: ; $(foreach tagdir, $(TAGDIRSS), mkdir -p ${tagdir})
cleantagdirs: ; $(foreach tagdir, $(TAGDIRS), rm -rf ${tagdir})
tags: tagdirs $(foreach tagdir, $(TAGDIRS), ${tagdir}/fennel)
TAGDOCS := $(foreach tagdir, $(TAGDIRS), \
	$(foreach file, index.html init.lua repl.fnl, \
		${tagdir}/${file}))

build: html lua tagdocs
html: $(HTML) index.html
tagdocs: tags $(TAGDOCS)
lua: $(LUA)
clean: cleantagdirs ; rm -f $(HTML) index.html $(LUA)

upload: $(HTML) $(LUA) $(TAGDIRS) index.html init.lua repl.fnl fennel.css \
		fengari-web.js repl-worker.js repl-worker.lua .htaccess fennel \
		see.html see.lua antifennel.lua see-worker.lua see-worker.js logo.svg
	rsync -r $^ fenneler@fennel-lang.org:fennel-lang.org/

conf/%.html: conf/%.fnl fennel/fennel ; fennel/fennel $< > $@

conf/thanks.html: conf/thanks.fnl fennel/fennel ; fennel/fennel $< > $@
conf/signup.cgi: conf/signup.fnl fennel/fennel
	echo "#!/usr/bin/env lua" > $@
	fennel/fennel --compile $< >> $@
	chmod 755 $@

uploadconf: conf/2020.html conf/2021.html conf/*.jpg conf/.htaccess fennelview.lua conf/signup.cgi
	rsync $^ fenneler@fennel-lang.org:conf.fennel-lang.org/

uploadv: conf/v
	rsync -r $^ fenneler@fennel-lang.org:conf.fennel-lang.org/

pullsignups:
	ls signups/ | wc -l
	rsync -rv fenneler@fennel-lang.org:conf.fennel-lang.org/signups/*fnl signups/
	ls signups/ | wc -l
	fennel signups.fnl

server: ; python -m SimpleHTTPServer 3003

.PHONY: build html tagdirs tagdocs lua clean cleantagdirs server \
		upload uploadv uploadconf pullsignups
