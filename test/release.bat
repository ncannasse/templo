@echo off
rm -rf release
mkdir release
mkdir release\templo
cp ../templo/*.* release/templo
cp ../temploc2.n ../haxelib.xml release
zip -q -r release.zip release
rm -rf release
