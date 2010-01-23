haxe -D FLEX_WRAP compile.hxml
c:\flex3\bin\mxmlc code\console.mxml -define=CONFIG::kong,true
move /Y code\console.swf shep-kong.swf && start shep-kong.swf
