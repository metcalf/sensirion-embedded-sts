drivers=sts3x
clean_drivers=$(foreach d, $(drivers), clean_$(d))
release_drivers=$(foreach d, $(drivers), release/$(d))

.PHONY: FORCE all $(release_drivers) $(clean_drivers) style-check style-fix

all: $(drivers)

$(drivers): sts-common/sts_git_version.c FORCE
	cd $@ && $(MAKE) $(MFLAGS)

sts-common/sts_git_version.c: FORCE
	git describe --always --dirty | \
		awk 'BEGIN \
		{print "/* THIS FILE IS AUTOGENERATED */"} \
		{print "#include \"sts_git_version.h\""} \
		{print "const char * STS_DRV_VERSION_STR = \"" $$0"\";"} \
		END {}' > $@ || echo "Can't update version, not a git repository"


$(release_drivers): sts-common/sts_git_version.c
	export rel=$@ && \
	export driver=$${rel#release/} && \
	export tag="$$(git describe --always --dirty)" && \
	export pkgname="$${driver}-$${tag}" && \
	export pkgdir="release/$${pkgname}" && \
	rm -rf "$${pkgdir}" && mkdir -p "$${pkgdir}" && \
	cp -r embedded-common/* "$${pkgdir}" && \
	cp -r sts-common/* "$${pkgdir}" && \
	cp -r $${driver}/* "$${pkgdir}" && \
	perl -pi -e 's/^sensirion_common_dir :=.*$$/sensirion_common_dir := ./' "$${pkgdir}/Makefile" && \
	perl -pi -e 's/^sts_common_dir :=.*$$/sts_common_dir := ./' "$${pkgdir}/Makefile" && \
	cd "$${pkgdir}" && $(MAKE) $(MFLAGS) && $(MAKE) clean $(MFLAGS) && cd - && \
	cd release && zip -r "$${pkgname}.zip" "$${pkgname}" && cd - && \
	ln -sfn $${pkgname} $@

release: clean $(release_drivers)

$(clean_drivers):
	export rel=$@ && \
	export driver=$${rel#clean_} && \
	cd $${driver} && $(MAKE) clean $(MFLAGS) && cd -

clean: $(clean_drivers)
	rm -rf release sts-common/sts_git_version.c

style-fix:
	@if [ $$(git status --porcelain -uno 2> /dev/null | wc -l) -gt "0" ]; \
	then \
		echo "Refusing to run on dirty git state. Commit your changes first."; \
		exit 1; \
	fi; \
	git ls-files | grep -e '\.\(c\|h\|cpp\)$$' | xargs clang-format -i -style=file;

style-check: style-fix
	@if [ $$(git status --porcelain -uno 2> /dev/null | wc -l) -gt "0" ]; \
	then \
		echo "Style check failed:"; \
		git diff; \
		git checkout -f; \
		exit 1; \
	fi;

