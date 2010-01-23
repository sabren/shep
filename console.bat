haxe -D FLEX_WRAP compile.hxml
c:\flex3\bin\mxmlc code\console.mxml -define=CONFIG::kong,false
move /Y code\console.swf . && start console.swf
