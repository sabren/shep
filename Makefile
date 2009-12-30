
haxe = "c:/Program Files/Motion-Twin/haxe/haxe.exe"
neko = "c:/Program Files/Motion-Twin/neko/neko.exe"
swfmill = ../alchementrix/tools/swfmill.exe

# main : game1.swf
main : assets.swf

game1.swf : assets.swf compile.hxml code/*.hx 
	$(haxe) compile.hxml

assets.swf : assets/assets.swfml
	$(swfmill) simple assets/assets.swfml assets.swf

clean:
	rm -f assets.swf game1.swf unittest.n
	tools\find -name "*~" -exec tools\rm {} ;


debug: game1.swf
	flashdebug10.exe game1.swf

.PHONY : test
test:
	$(haxe) unittest.hxml
	$(neko) unittest.n
