SRCDIR = src
ATDGEN = atdgen
ATDGEN_SOURCES = $(SRCDIR)/types.ml  
ATDGEN_FLAGS = -j-std -j-custom-fields \
	"(fun a b -> Printf.printf \"Unknown field: %s\\t(%s)\\n\" b a)"	

default: build

$(SRCDIR)/%.ml: src/%.atd
	$(ATDGEN) $(ATDGEN_FLAGS) $<

# OASIS_START
# DO NOT EDIT (digest: 7000995ee357d74b16bebaa9a87a2c1a)

SETUP = ocaml setup.ml

doc: setup.data build
	$(SETUP) -doc $(DOCFLAGS)

test: setup.data build
	$(SETUP) -test $(TESTFLAGS)

all:
	$(SETUP) -all $(ALLFLAGS)

install: setup.data
	$(SETUP) -install $(INSTALLFLAGS)

uninstall: setup.data
	$(SETUP) -uninstall $(UNINSTALLFLAGS)

reinstall: setup.data
	$(SETUP) -reinstall $(REINSTALLFLAGS)

clean:
	$(SETUP) -clean $(CLEANFLAGS)

distclean:
	$(SETUP) -distclean $(DISTCLEANFLAGS)

setup.data:
	$(SETUP) -configure $(CONFIGUREFLAGS)

.PHONY: doc test all install uninstall reinstall clean distclean configure

# OASIS_STOP

build: setup.data $(ATDGEN_SOURCES)
	$(SETUP) -build $(BUILDFLAGS)

opam-release:
	$(eval TEMPLATE_DIR:=opam-template)
	$(eval RELEASE_DIR:=opam-releases)
	$(eval NAME:=$(shell oasis query name))
	$(eval VERSION:=$(shell oasis query version))
	$(eval PACKAGE:=$(NAME).$(VERSION))
	$(eval DIR:=$(RELEASE_DIR)/$(PACKAGE))
	mkdir -p $(DIR)
	tar -cjf $(RELEASE_DIR)/$(PACKAGE).tar.bz2 \
		--transform 's,^\.,$(PACKAGE),' \
		--exclude-from=.gitignore \
		--exclude=.git \
		--exclude=$(RELEASE_DIR) .
	for f in descr opam url; do \
		./oasis-vars "$(TEMPLATE_DIR)/$$f" > $(DIR)/$$f; \
	done
