###############################################################################
# Project Configuration

TARGET				= paper.pdf
MAIN					= main

#####

TARGET_BASE 	= $(basename $(TARGET))

################################################################################
# Command Configuration

PDFLATEX			= pdflatex
BIBTEX				= bibtex
EPS_TO_PDF		= epstopdf
OBJ_TO_EPS		= tgif -print -eps -color -stdout
GNUPLOT				= gnuplot
SPELLCHECK		= aspell -t list

################################################################################
# Gathering Information

TEX_MAIN := $(MAIN).tex

TEX_ALL := $(shell search=$(TEX_MAIN); all=; \
				while [ -n "$$search" ] ; do \
					all="$$all $$search"; \
					search=`egrep "^[^%]*\\input" $$search | \
						sed -En 's/.*input[^\{]*\{(.+)\}/\1.tex/p'`; \
				done; \
				echo "$$all")

GFX_ALL := $(shell for t in $(TEX_ALL); do \
				cat $$t | \
				egrep '^[^%]*\\includegraphics' | \
				sed -En 's/.*includegraphics(\[.+\])?\{([^\{]*)\}.*/\2/p'; \
				done)

GFX_FILES := $(shell for g in $(GFX_ALL); do \
					ls $$g.* | \
					egrep "(\.obj|\.eps)$$" | \
					sed -E 's/\.[^ ]+/\.pdf/g'; \
					done)

GNUPLOT_FILES := $(shell for g in $(GFX_ALL); do \
							test -e $$g.p && \
							test ! -e $$g.eps -a ! -e $$g.obj && \
							echo $$g.pdf; \
							done)

BIB_FILES := $(shell cat $(TEX_MAIN) | \
					egrep '^[^%]*\\bibliography\{' | \
					sed -E -e 's/.*\{([^\{]+)\}.*/\1/g' \
						-e 's/([^,\{\}]+)/\1.bib/g' \
						-e 's/,/ /g')	

################################################################################
# Command Rules

all: $(TARGET)

$(TARGET): $(TEX_ALL) $(GFX_FILES) $(GNUPLOT_FILES) $(BIB_FILES)
	$(PDFLATEX) $(TEX_MAIN) </dev/null
	-$(BIBTEX) $(MAIN)
	$(PDFLATEX) $(TEX_MAIN) </dev/null
	$(PDFLATEX) $(TEX_MAIN) </dev/null
	mv $(MAIN).pdf $@

debug:
	@echo "TEX_MAIN = $(TEX_MAIN)"
	@echo "TEX_ALL = $(TEX_ALL)"
	@echo "GFX_ALL = $(GFX_ALL)"
	@echo "GFX_FILES = $(GFX_FILES)"
	@echo "GNUPLOT_FILES = $(GNUPLOT_FILES)"
	@echo "BIB_FILES = $(BIB_FILES)"

clean:
	rm -f $(TARGET) $(TARGET_BASE)-gray.pdf $(TARGET_BASE)-final.pdf \
		*~ *.bbl *.blg *.log *.aux $(MAIN).out $(GFX_FILES) $(GNUPLOT_FILES)

grayscale: $(TARGET_BASE)-gray.pdf

$(TARGET_BASE)-gray.pdf: $(TARGET)
	gs -sOutputFile=$@ -sDEVICE=pdfwrite -sColorConversionStrategy=Gray \
		-dProcessColorModel=/DeviceGray -dNOPAUSE \
		-dBATCH -dAutoRotatePages=/None $(TARGET)

diff: $(TARGET_BASE)-final.pdf

$(TARGET_BASE)-diff.pdf: $(TEX_ALL) $(GFX_FILES) $(GNUPLOT_FILES) $(BIB_FILES)
	$(PDFLATEX) "\\def\\isDiff{1} \\input{$(TEX_MAIN)}"
	-$(BIBTEX) $(MAIN)
	$(PDFLATEX) "\\def\\isDiff{1} \\input{$(TEX_MAIN)}"
	$(PDFLATEX) "\\def\\isDiff{1} \\input{$(TEX_MAIN)}"
	mv $(MAIN).pdf $@

finalized: $(TARGET_BASE)-final.pdf

$(TARGET_BASE)-final.pdf: $(TEX_ALL) $(GFX_FILES) $(GNUPLOT_FILES) $(BIB_FILES)
	$(PDFLATEX) "\\def\\isFinalized{1} \\input{$(TEX_MAIN)}"
	-$(BIBTEX) $(MAIN)
	$(PDFLATEX) "\\def\\isFinalized{1} \\input{$(TEX_MAIN)}"
	$(PDFLATEX) "\\def\\isFinalized{1} \\input{$(TEX_MAIN)}"
	mv $(MAIN).pdf $@

spellcheck:

################################################################################
# File -> File Rules

%.pdf: %.eps
	$(EPS_TO_PDF) $<

%.pdf: %.obj
	$(OBJ_TO_EPS) $< | \
	$(EPS_TO_PDF) -f -o=$@

%.pdf: %.p
	$(GNUPLOT) $< | \
	$(EPS_TO_PDF) -f -o=$@

