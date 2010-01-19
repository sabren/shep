import flash.display.MovieClip;
import flash.events.Event;

class Assets {}
class ClockFont extends flash.text.Font {}

class BorderClip extends MovieClip {}
class GlassLayer extends MovieClip {}

class BG0000 extends MovieClip {}
class BG0001 extends MovieClip {}
class BG0002 extends MovieClip {}
class BG0003 extends MovieClip {}
class BG0004 extends MovieClip {}
class BG0005 extends MovieClip {}
class BG0006 extends MovieClip {}
class BG0007 extends MovieClip {}
class BG0009 extends MovieClip {}

class FG0000 extends MovieClip {}
class FG0001 extends MovieClip {}
class FG0002 extends MovieClip {}
class FG0003 extends MovieClip {}
class FG0004 extends MovieClip {}
class FG0005 extends MovieClip {}
class FG0006 extends MovieClip {}
class FG0007 extends MovieClip {}
class FG0009 extends MovieClip {}

class ShepClip extends MovieClip {}
class GlowClip extends MovieClip {}
class BallClip extends MovieClip {}
class DoorClip extends MovieClip {}
class SpinnerClip extends MovieClip {}
class RedBallClip extends MovieClip {}
class CargoClip extends MovieClip {}
class CrateClip extends MovieClip {}

class SoundIcon extends MovieClip {}
class MuteIcon extends MovieClip {}


class PocketGlow extends MovieClip {}

// Putting the stops in the animated swf
// caused the game to lock up... I guess
// haxe or swfmill couldn't handle it.
// So, we do this instead:
class PocketClip extends MovieClip {


  static var HALF_OPENED:Int =  6;
  static var FULLY_OPEN:Int = 11;
  static var HALF_CLOSED:Int = 16;

  public function new() {
    super();
    addChild(new PocketGlow());
    addEventListener(Event.ENTER_FRAME, onEnterFrame);
  }

  public function swallow() {
    gotoAndPlay(HALF_CLOSED);
  }

  public function openWide() {
    gotoAndPlay(HALF_OPENED+1);
  }

  private function onEnterFrame(e) {
    var frame = this.currentFrame;
    switch (frame) {
    case HALF_OPENED:
      stop();
    case FULLY_OPEN:
      stop();
    default: 
      // do nothing
    }
  }
}


class RedPocketClip extends PocketClip {}
