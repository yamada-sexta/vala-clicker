BUILDDIR=build

all: compile

setup:
	meson setup $(BUILDDIR)

compile:
	ninja -C $(BUILDDIR)

run: compile
	./$(BUILDDIR)/src/vala-clicker

clean:
	rm -rf $(BUILDDIR)

.PHONY: all setup compile run clean
