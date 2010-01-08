import flash.media.Sound;

class FuseSound extends Sound {}
class WallSound extends Sound {}
class DoorSound extends Sound {}
class PocketSound extends Sound {}
class AlertSound1 extends Sound {}
class AlertSound2 extends Sound {}
class AlertSound3 extends Sound {}
class ThrustSound extends Sound {}
class VictorySound extends Sound {}
class DefeatSound extends Sound {}

class SoundManager {

  private var _alert1:Sound;
  private var _alert2:Sound;
  private var _alert3:Sound;
  private var _wall:Sound;
  private var _pocket:Sound;
  private var _fuse:Sound;
  private var _door:Sound;
  private var _thrust:Sound;
  private var _victory:Sound;
  private var _defeat:Sound;
  
  public static var muted : Bool = false;

  public function new () {
    _alert1 = new AlertSound1();
    _alert2 = new AlertSound2();
    _alert3 = new AlertSound3();
    _wall = new WallSound();
    _pocket = new PocketSound();
    _fuse = new FuseSound();
    _door = new DoorSound();
    _thrust = new ThrustSound();
    _victory = new VictorySound();
    _defeat = new DefeatSound();
  }

  public static function toggle() {
    muted = ! muted;
  }


  public function alert1(){
    if (!muted) _alert1.play();
  }
  public function alert2(){
    if (!muted) _alert2.play();
  }
  public function alert3(?start, ?reps){
    if (!muted) _alert3.play(start, reps);
  }
  public function wall(){
    if (!muted) _wall.play();
  }
  public function pocket(){
    if (!muted) _pocket.play();
  }
  public function fuse(){
    if (!muted) _fuse.play();
  }
  public function door(){
    if (!muted) _door.play();
  }
  public function thrust(){
    if (!muted) _thrust.play();
  }
  public function victory(){
    if (!muted) _victory.play();
  }
  public function defeat(){
    if (!muted) _defeat.play();
  }


}