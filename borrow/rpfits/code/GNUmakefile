#-----------------------------------------------------------------------------
# Makefile which checks out RPFITS sources.
#
# $Id$
#-----------------------------------------------------------------------------

comma := ,

SOURCES := $(subst $(comma)v,,$(notdir $(wildcard RCS/*,v)))

SUBDIRS := $(subst /RCS,,$(wildcard */RCS))

export SUBDIRS

% :: RCS/%,v
	-@ co $@

%,v : ;

.PHONY : all

all : $(SOURCES)
	-@ for i in $$SUBDIRS ; do \
	      $(MAKE) -C $$i -f ../GNUmakefile ; \
	   done

show :
	-@ echo "SOURCES = $(SOURCES)"
	-@ echo "SUBDIRS = $(SUBDIRS)"
