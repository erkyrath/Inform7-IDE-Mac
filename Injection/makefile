define make-ni
	echo "Making ni"
	perl "(assorted scripts)/advancebuild.pl"
	perl "Tools/inweb.pl" -tangle "Woven/NI.c"
	gcc  -arch i386 -arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk -ansi -g -o Injections/ni Woven/NI.c
endef

define make-cblorb
	echo "Making cBlorb"
	gcc -arch i386 -arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk -ansi -g -o Injections/cBlorb/cBlorb Injections/cBlorb/cBlorb.c
endef

define copy-i6
	echo "Copying I6 compiler"
	cp -f Injections/inform-6.31-biplatform Inform.app/Contents/Resources/Compilers
endef

define copy-cblorb
	echo "Copying cBlorb tool"
	cp -f Injections/cBlorb/cBlorb Inform.app/Contents/Resources/Compilers
endef

define copy-ni
	echo "Copying NI compiler"
	cp -f Injections/ni Inform.app/Contents/Resources/Compilers
endef

define copy-library
	echo "Copying I6 library"
	mkdir -p Inform.app/Contents/Resources/Library/Natural
	touch Inform.app/Contents/Resources/Library/Natural
	cp -R -f Injections/Natural Inform.app/Contents/Resources/Library
endef

define copy-extensions
	echo "Copying extensions"
	mkdir -p Inform.app/Contents/Resources/Inform7/Extensions
	mkdir -p "Inform.app/Contents/Resources/Inform7/Extensions/Emily Short"
	mkdir -p "Inform.app/Contents/Resources/Inform7/Extensions/Graham Nelson"
	mkdir -p "Inform.app/Contents/Resources/Inform7/Extensions/Reserved/Templates"
	rm -f Inform.app/Contents/Resources/Inform7/Extensions/Emily\ Short/*
	rm -f Inform.app/Contents/Resources/Inform7/Extensions/Graham\ Nelson/*
	rm -f Inform.app/Contents/Resources/Inform7/Extensions/Reserved/Templates/*
	rm -f -d Inform.app/Contents/Resources/Inform7/Extensions/Reserved/*
	touch Inform.app/Contents/Resources/Inform7/Extensions
	cp -R -f Injections/Extensions Inform.app/Contents/Resources/Inform7
endef

define make-doc
	echo "Making documentation HTML"
	perl Tools/indoc.pl --rewrite-standard-rules osx_app
	perl Tools/indoc.pl windows_app
endef

define copy-doc
	echo "Copying documentation HTML"
	rm -f Inform.app/Contents/Resources/chap*.html
	rm -f Inform.app/Contents/Resources/English.lproj/doc*.html
	rm -f Inform.app/Contents/Resources/English.lproj/ex*.html
	cp -f Injections/Documentation/index.html Inform.app/Contents/Resources
	cp -f Injections/Documentation/examples.html Inform.app/Contents/Resources
	cp -f Injections/Documentation/extensions.html Inform.app/Contents/Resources
	cp -f Injections/Documentation/recipes.html Inform.app/Contents/Resources
	cp -f Injections/Documentation/manifest.txt Inform.app/Contents/Resources
	cp -f Injections/Documentation/chap*.html Inform.app/Contents/Resources
	cp -f Injections/Documentation/English.lproj/doc*.html Inform.app/Contents/Resources/English.lproj
	cp -f Injections/Documentation/English.lproj/ex*.html Inform.app/Contents/Resources/English.lproj
	touch Inform.app/Contents/Resources/English.lproj/doc1.html
endef

define copy-doc-images
	echo "Updating documentation images"
	mkdir -p Inform.app/Contents/Resources/doc_images
	touch Inform.app/Contents/Resources/doc_images
	cp -f Injections/doc_images/[A-Za-z]*.* Inform.app/Contents/Resources/doc_images
endef

define copy-error-pages
	echo "Updating HTML error pages"
	cp -f Injections/Error*pages/[A-Za-z]*.* Inform.app/Contents/Resources/English.lproj
	touch Inform.app/Contents/Resources/English.lproj/Error0.html
endef

define make-rtp-pages
	echo "Making run-time problem HTML pages"
	perl Tools/inrtps.pl Run-Time\ Problems Injections/RTP\ pages font
	perl Tools/inrtps.pl Run-Time\ Problems Injections/Documentation\ for\ Windows/sections nofont
endef

define copy-rtp-pages
	echo "Copying RTP error pages"
	cp -f Injections/RTP*pages/[A-Za-z]*.* Inform.app/Contents/Resources/English.lproj
	touch Inform.app/Contents/Resources/English.lproj/RTP_P1.html
endef

define copy-icons
	echo "Updating miscellaneous icons"
	cp -f Injections/Miscellaneous/[A-Za-z]*.* Inform.app/Contents/Resources
	touch Inform.app/Contents/Resources/Welcome*Background.png
endef

define copy-scene-icons
	echo "Updating scene images"
	mkdir -p Inform.app/Contents/Resources/scene_icons
	touch Inform.app/Contents/Resources/scene_icons
	cp -f Injections/scene_icons/[A-Za-z]*.* Inform.app/Contents/Resources/scene_icons
endef

define copy-map-icons
	echo "Updating map images"
	mkdir -p Inform.app/Contents/Resources/map_icons
	touch Inform.app/Contents/Resources/map_icons
	cp -f Injections/map_icons/[A-Za-z]*.* Inform.app/Contents/Resources/map_icons
endef


.PHONY: all
all: \
		Inform.app/Contents/Resources/Compilers/ni \
		Inform.app/Contents/Resources/Compilers/cBlorb \
		Inform.app/Contents/Resources/Compilers/inform-6.31-biplatform \
		Inform.app/Contents/Resources/Library/Natural \
		Inform.app/Contents/Resources/Inform7/Extensions \
		Inform.app/Contents/Resources/index.html \
		Inform.app/Contents/Resources/doc_images \
		Inform.app/Contents/Resources/English.lproj/Error0.html \
		Inform.app/Contents/Resources/English.lproj/RTP_P1.html \
		Inform.app/Contents/Resources/Welcome*Background.png \
		Inform.app/Contents/Resources/scene_icons \
		Inform.app/Contents/Resources/map_icons
	echo "Make complete"

# Injecting I6
Inform.app/Contents/Resources/Compilers/inform-6.31-biplatform: Injections/inform-6.31-biplatform
	$(call copy-i6)

# Injecting I6
Inform.app/Contents/Resources/Compilers/cBlorb: Injections/cBlorb/cBlorb
	$(call copy-cblorb)

# Injecting NI
Inform.app/Contents/Resources/Compilers/ni: Injections/ni
	$(call copy-ni)

# Compiling NI
Injections/ni: Literate*Source/Chapter*/*.w
	$(call make-ni)

# The "cBlorb" blorbing agent
Injections/cBlorb/cBlorb: Injections/cBlorb/cBlorb.c
	$(call make-cblorb)

# The I6 library
Inform.app/Contents/Resources/Library/Natural: Injections/Natural/[A-Za-z]*.*
	$(call copy-library)

# The extensions
Inform.app/Contents/Resources/Inform7/Extensions: \
		Injections/Extensions/Emily\ Short/[A-Za-z]* \
		Injections/Extensions/Graham\ Nelson/[A-Za-z]* \
		Injections/Extensions/Reserved/[A-Za-z]*.* \
		Injections/Extensions/Reserved/[A-Za-z]/Templates*.*
	$(call copy-extensions)


# The in-application HTML documentation, including all examples
Inform.app/Contents/Resources/index.html: Injections/Documentation/index.html
	$(call copy-doc)

# The in-application HTML documentation, including all examples
Injections/Documentation/index.html: Documentation.txt Documentation*Examples/*.txt
	$(call make-doc)

# Documentation images
Inform.app/Contents/Resources/doc_images: Injections/doc_images/[A-Za-z]*.*
	$(call copy-doc-images)

# HTML error pages, displayed on the Problems tab
Inform.app/Contents/Resources/English.lproj/Error0.html: Injections/Error*pages/[A-Za-z]*.*
	$(call copy-error-pages)

# Run-time problem HTML pages
Inform.app/Contents/Resources/English.lproj/RTP_P1.html: Injections/RTP*pages/RTP_P1.html
	$(call copy-rtp-pages)

Injections/RTP*pages/RTP_P1.html: \
		Run-Time*Problems/model.html Run-Time*Problems/texts.txt
	$(call make-rtp-pages)


# Miscellaneous icons in Resources folder
Inform.app/Contents/Resources/Welcome*Background.png: Injections/Miscellaneous/[A-Za-z]*.*
	$(call copy-icons)

# Scene index icons
Inform.app/Contents/Resources/scene_icons: Injections/scene_icons/[A-Za-z]*.*
	$(call copy-scene-icons)

# World index icons
Inform.app/Contents/Resources/map_icons: Injections/map_icons/[A-Za-z]*.*
	$(call copy-map-icons)


.PHONY: force
force:
	$(call make-ni)	
	$(call make-cblorb)
	$(call copy-i6)
	$(call copy-ni)
	$(call copy-cblorb)
	$(call copy-library)
	$(call copy-extensions)
	$(call make-doc)
	$(call copy-doc)
	$(call copy-doc-images)
	$(call copy-error-pages)
	$(call make-rtp-pages)
	$(call copy-rtp-pages)
	$(call copy-icons)
	$(call copy-scene-icons)
	$(call copy-map-icons)

.PHONY: copyall
copyall:
	$(call copy-i6)
	$(call copy-ni)
	$(call copy-cblorb)
	$(call copy-library)
	$(call copy-extensions)
	$(call copy-doc)
	$(call copy-doc-images)
	$(call copy-error-pages)
	$(call copy-rtp-pages)
	$(call copy-icons)
	$(call copy-scene-icons)
	$(call copy-map-icons)

.PHONY: ext
ext:
	$(call copy-extensions)
