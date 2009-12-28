
import flash.events.Event;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.events.KeyboardEvent;
import flash.filters.GlowFilter;
import flash.filters.DropShadowFilter;
import flash.ui.Keyboard;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.utils.SetIntervalTimer;
import flash.media.Sound;

class Game1
{

  var world : phx.World;
  var root : MovieClip;

  var target : phx.Body;
  var cuebot : phx.Body;

  public function new(root:MovieClip) {
    this.root = root;
    var stage = root.stage;
    stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    stage.addEventListener(MouseEvent.MOUSE_DOWN, onClick);

    var broadphase = new phx.col.SortedList();
    var boundary = new phx.col.AABB(-2000, -2000, 2000, 2000);
    world = new phx.World(boundary, broadphase);


    
    cuebot = new phx.Body(100, 100);
    cuebot.addShape(new phx.Circle(20, new phx.Vector(0, 0)));

    target = new phx.Body(500, 300);
    target.addShape(new phx.Circle(10, new phx.Vector(0, 0)));

    world.addBody(cuebot);
    world.addBody(target);
    world.gravity.set(0,0.1875);


    var w = 800;
    var h = 575;
    var b = 25; // border
    world.addStaticShape(phx.Shape.makeBox(w, b, 0, -b)); // top
    world.addStaticShape(phx.Shape.makeBox(10, h, -b, 0)); // left
    world.addStaticShape(phx.Shape.makeBox(10, h, w, 0)); // right
    world.addStaticShape(phx.Shape.makeBox(w, b, 0, h)); // bottom

  }



  function updateWorld() {
    world.step(0.5, 1);
  }

  function drawWorld() {
    var g = root.graphics;
    g.clear();
    var fd = new phx.FlashDraw(g);
    fd.drawWorld(world);
  }


  public function onEnterFrame(_) {
    updateWorld();
    drawWorld();
  }

  public function onClick(_) {
    target.setPos(root.mouseX, root.mouseY);
    target.setSpeed(5, -10);
  }


  static function main() {
    var root = flash.Lib.current;
    var game = new Game1(root);
  }

}
