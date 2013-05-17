@echo off
rm -rf release
mkdir release
mkdir release\templo
cp ../templo/*.* release/templo
cp ../temploc2.n ../haxelib.json release
haxe -main Run -neko run.n
cp run.n release
zip -q -r release.zip release
rm -rf release
