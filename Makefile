BUILDDIR=build

all: compile

setup:
	meson setup $(BUILDDIR)

compile:
	ninja -C $(BUILDDIR)

run: compile
	./$(BUILDDIR)/src/vala-clicker

flatpak:
	./build-flatpak.sh

clean:
	rm -rf $(BUILDDIR) flatpak-build .flatpak-builder

.PHONY: all setup compile run clean flatpak
