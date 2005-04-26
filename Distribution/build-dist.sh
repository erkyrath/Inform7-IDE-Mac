#!/bin/sh

#
# Andrew Hunter, 26/04/05
#
# Shell script to turn Inform into a nice disk image. Inform.app should be in ./, ../ or ../build/
#

# Locate Inform.app
if [ -e "./Inform.app" ]; then
	INFORM="./Inform.app"
elif [ -e "../Inform.app" ]; then
	INFORM="../Inform.app"
elif [ -e "../build/Inform.app" ]; then
	INFORM="../build/Inform.app"
else
	echo "Unable to find Inform.app: giving up"
	exit 1
fi

echo "Found Inform.app at '$INFORM'"

# Construct the disk image
if [ -e "/Volumes/Inform" ]; then
	echo "Found something already mounted at /Volumes/Inform: giving up"
	exit 1
fi

if [ -e "inform.dmg" ]; then
	echo -n "Removing old inform.dmg..."
	rm inform.dmg
fi

echo -n "Creating inform.dmg..."
hdiutil create -size 30m -fs HFS+ -volname "Inform" ./inform.dmg >/dev/null || (echo Failed; exit 1)

echo -n "Mounting..."
hdiutil mount ./inform.dmg -readwrite >/dev/null || (echo Failed; exit 1)

if [ -e "/Volumes/Inform" ]; then
	echo OK
else
	echo "Failed to mount: giving up"
	exit 1
fi

# Copy files
echo -n Copying files...

cp -Ra "$INFORM" /Volumes/Inform || (echo Failed; exit 1)
cp bgimage.png /Volumes/Inform/.background.png || (echo Failed; exit 1)

echo OK

# Arrange the icons
echo -n "Arranging..."

osascript <<NO_MORE_SPOONS
	tell application "Finder"
		activate
		set informdisk to disk "Inform"
		set inform to file "Inform.app" of informdisk
		set win to container window of informdisk
		
		open win
		
		set toolbar visible of win to false
		set current view of win to icon view
		set bounds of win to {200, 200, 560, 456}
		
		set arrangement of icon view options of win to not arranged
		set icon size of icon view options of win to 128
		set position of inform to {85, 82}
		
		tell informdisk to eject
	end tell
NO_MORE_SPOONS

echo OK

# Licensify the image
echo -n "Converting to read only..."

hdiutil convert ./inform.dmg -format UDCO -o ./inform-compressed.dmg >/dev/null || (echo Failed; exit 1)

echo -n "Adding license info..."

hdiutil unflatten ./inform-compressed.dmg >/dev/null || (echo Failed; exit 1)
/Developer/Tools/Rez -a SLA.rez -o inform-compressed.dmg || (echo Failed; exit 1)
hdiutil flatten ./inform-compressed.dmg >/dev/null || (echo Failed; exit 1)

mv inform-compressed.dmg inform.dmg

echo OK



