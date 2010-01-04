
import flash.geom.ColorTransform;
import flash.events.Event;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.KeyboardEvent;
import flash.filters.GlowFilter;
import flash.filters.BlurFilter;
import flash.filters.DropShadowFilter;
import flash.ui.Keyboard;
import flash.text.TextFormat;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.AntiAliasType;
import flash.utils.SetIntervalTimer;
import flash.media.Sound;
import flash.net.URLLoader;
import flash.net.URLRequest;

class ClockFont extends flash.text.Font {}
class BG0001 extends MovieClip {}

class FG0000 extends MovieClip {}
class FG0001 extends MovieClip {}
class FG0002 extends MovieClip {}
class FG0003 extends MovieClip {}
class FG0004 extends MovieClip {}
class FG0005 extends MovieClip {}
class FG0006 extends MovieClip {}
class FG0007 extends MovieClip {}
class FG0008 extends MovieClip {}
class FG0009 extends MovieClip {}

class ShepClip extends MovieClip {}
class BallClip extends MovieClip {}
class PocketClip extends MovieClip {}

class BodyClip {
  public var clip : MovieClip;
  public var body : phx.Body;
  public var code : Int; // for doors and locks
  public function new(body, clip) {
    this.body = body;
    this.clip = clip;
  }
}

class Pocket extends phx.Body {
  public var code : Int;
}

class Game1
{


  // config
  static var timeLimit = 120;
  static var blurAmount : Int = 10;
  static var spinnerVelocity :Float= 0.05;
  static var spinnerTorque :Float = 0.05;

  var world : phx.World;
  var parent : Sprite;

  var floatyWall : phx.Material;
  var bouncyWall : phx.Material;
  var robotParts : phx.Material;

  var pockets : Array<Pocket>;
  var cuebot : phx.Body;

  var done : Bool;
  var paused: Bool;
  var keyboardControl: Bool;

  var loader : URLLoader;
  var svg : Xml;

  var clock:FlashClock;
  var clockText:TextField;

  var physaxeLayer : MovieClip;
  var socketGlow : GlowFilter;

  var currentLevel : Int;
  var bg : MovieClip;
  var mg : MovieClip;
  var fg : MovieClip;
  var blurFilter : BlurFilter;

  var shepClip : MovieClip;
  var showPhysics : Bool;
  var smallballs : Array<BodyClip>;
  var doors : Array<BodyClip>;
  var spinners : Array<phx.Body>; // @TODO: BodyClip
  var starfield : StarField;


  public var winCallback : Float -> Void;
  public var loseCallback : Void -> Void;

  public function new(parent:Sprite) {

    this.parent = parent;

    smallballs = [];
    pockets = [];
    doors = [];

    socketGlow = new GlowFilter(0xFFFF00, 1, 7.5, 7.5, 4);
    // phx.Material(restitution, friction, density );
    floatyWall = new phx.Material(0.5, 2, 100);
    bouncyWall = new phx.Material(1, 2, Math.POSITIVE_INFINITY);
    robotParts = new phx.Material(0.5, 20, 20);

    starfield = new StarField(800,575);
    parent.addChild(starfield);

    bg = new BG0001();
    blurFilter = new BlurFilter(0,0);
    bg.filters = [blurFilter];
    parent.addChild(bg);

    physaxeLayer = new MovieClip();
    parent.addChild(physaxeLayer);

    mg = new MovieClip();
    parent.addChild(mg);

    fg = new MovieClip();
    parent.addChild(fg);


    clock = new FlashClock();

    var ds = new ClockFont();
    var fmt = new TextFormat(ds.fontName, 24, 0xFF0000);


    clockText = new TextField();
    clockText.embedFonts = true;
    clockText.x = 400;
    clockText.y = 0;
    clockText.antiAliasType = AntiAliasType.ADVANCED;
    clockText.background = false;
    //clockText.backgroundColor = ;
    clockText.multiline = false;
    clockText.visible = true;

    clockText.defaultTextFormat = fmt;
    clockText.setTextFormat(fmt);
    clockText.text = "00:00";

    // center it ourselves, because the font isn't fixed-width
    // and we don't want the numbers jiggling left and right 
    // on every tick
    clockText.autoSize = TextFieldAutoSize.CENTER;
    clockText.x = (parent.width /2 - clockText.textWidth - 2);

    parent.addChild(clockText);

    done = true;
    resetWorld(1);

    // save this to the end so world is ready to go for first frame event
    parent.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    parent.addEventListener(MouseEvent.MOUSE_DOWN, onClick);
    if (flash.Lib.current.stage != null)
      flash.Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown );
    // nothing below here should edit the world!
  }

  public function onEnterFrame(e) {
    if (! (done || paused)) {
      updateWorld();
      checkForWin();
      checkForLoss();
      drawWorld();
      updateClock();
    }
  }

  public function updateClock() {
    clockText.text = clock.toString();
  }

  public function resetWorld(level:Int) {

    done = true;

    var broadphase = new phx.col.SortedList();
    var boundary = new phx.col.AABB(-2000, -2000, 2000, 2000);
    world = new phx.World(boundary, broadphase);

    clearClip(mg);

    cuebot = new phx.Body(10, 10);
    cuebot.addShape(new phx.Circle(20, new phx.Vector(0, 0), robotParts));
    world.addBody(cuebot);

    var png = new ShepClip();
    shepClip = new MovieClip();
    shepClip.addChild(png);
    png.x = -21;
    png.y = -21;

    var w = 800;
    var h = 575;
    var b = 25; // border
    
    addWall(phx.Shape.makeBox(w, b, 0, 0)); // top
    addWall(phx.Shape.makeBox(b, h-(2*b), 0, b)); // left
    addWall(phx.Shape.makeBox(b, h-(2*b), w-b, b)); // right
    addWall(phx.Shape.makeBox(w, b, 0, h-b)); // bottom
    
    try { haxe.Log.clear(); } catch (e:Dynamic){}
    loadLevel(level);

  }

  function addWall(shape:phx.Shape, ?mat):Void {
    shape.material = (mat != null) ? mat : bouncyWall;
    world.addStaticShape(shape);
  }

  function updateWorld() {
    world.step(1, 25);
    
    // friction:
    var friction = 0.985;
    var oldv = cuebot.v;
    cuebot.setSpeed(oldv.x * friction, oldv.y * friction);
    for (b in smallballs) {
      oldv = b.body.v;
      b.body.setSpeed(oldv.x * friction, oldv.y * friction);
    }

    // power the spinners:
    for (s in spinners) {
      s.w = spinnerVelocity;
      s.t = spinnerTorque;
    }

  }

  function checkForWin() {

    for (pocket in pockets) {
      for (arb in pocket.arbiters) {
	var shape = (arb.s1.body == pocket) ? arb.s2 : arb.s1;
	if (shape.body == cuebot) {
	  if (smallballs.length == 0) {
	    onWin();
	  }
	} else {
	  for (b in smallballs) {
	    if (shape.body == b.body) {
              if (b.code == pocket.code) {
		smallballs.remove(b);
		mg.removeChild(b.clip);
		world.removeBody(shape.body);
		
		if (pocket.code > 0) {
		  for (d in doors) {
		    if (d.code == b.code)
		      doors.remove(d);
		    if (d.clip != null) 
		      mg.removeChild(d.clip);
		    world.removeBody(d.body);
		    break;
		  }
		}

		break;
	      }
	    }
	  }
	}
      }
    }
  }

  function checkForLoss() {
    if (clock.timeCount <= 0) {
      onLoss();
    }
  }

  function drawWorld() {
    var g = physaxeLayer.graphics;
    g.clear();

    if (showPhysics) {
      var fd = new phx.FlashDraw(g);
      //fd.boundingBox.line = 0x000000;
      //fd.contact.line = 0xFF0000;
      //fd.sleepingContact.line = 0xFF00FF;
      // fd.staticShape.fill = 0x00FF00;
      //fd.drawCircleRotation = true;
      fd.drawWorld(world);
    }

    var g = fg.graphics;
    g.clear();
    drawVector(g);

    for (b in smallballs) {
      b.clip.x = b.body.x;
      b.clip.y = b.body.y;
      b.clip.rotation = rad2deg(b.body.a);
    }


    if (cuebot.arbiters.isEmpty()) {
      if (blurFilter.blurX > 0) {
	blurFilter.blurX -= 0.5;
      }
      if (blurFilter.blurX < 0) {
	blurFilter.blurX = 0;
      }
    } else {
	blurFilter.blurX = 10;
    }
    blurFilter.blurY = blurFilter.blurX;
    bg.x = blurFilter.blurX / 2.5;
    bg.filters = [blurFilter];


    shepClip.x = cuebot.x;
    shepClip.y = cuebot.y;
    
  }


  function calcVector(r:Int) {
    var x1 = cuebot.x;
    var y1 = cuebot.y;
    
    var x2 = parent.mouseX;
    var y2 = parent.mouseY;

    var rise = (y2 - y1);
    var run = (x2 - x1);
    if (run == 0) {
      return new phx.Vector(0, rise);
    } else {
      var m = rise / run;
      var vx = Math.sqrt(r) / Math.sqrt(m*m+1);
      vx *= (x2 > x1) ? 1 : -1;
      var vy = m * vx;
      return new phx.Vector(vx, vy);
    }
  }

  function rad2deg(rad:Float) {
    return  180 * rad / Math.PI;
  }

  function deg2rad(deg:Float) {
    return deg * Math.PI / 180;
  }
  
  function rad2vec(r:Float) {
    return new phx.Vector(Math.cos(r), Math.sin(r));
  }



  public function shepClipVector() {
    return rad2vec(deg2rad(shepClip.rotation-90));
  }



  function drawVector(g:flash.display.Graphics) {

    // draw a line from the bot to the mouse
    // but scaled down to n units

    /* maxima session: 
       intersection of a line and circle of radius r
       if line passes through origin and circle centered at origin
       
       (%i27) y^2=r-x^2, y=m*x;
       (%o27) m^2*x^2=r-x^2
       (%i28) solve(%o27,x);
       (%o28) [x=-sqrt(r)/sqrt(m^2+1),x=sqrt(r)/sqrt(m^2+1)]
    */

    
    var r = 150;
    var v:phx.Vector;

    if (keyboardControl) {
      v = shepClipVector().mult(10);

    } else {
      v = calcVector(r);

      if (v.x == 0) {
	shepClip.rotation = v.y <= 0 ? 0 : 180;
      } else {
	var slope = v.y / v.x;
	shepClip.rotation = 90 + rad2deg( Math.atan(slope));
	if (v.x < 0)
	  shepClip.rotation += 180;
      }
    }

      g.moveTo(cuebot.x, cuebot.y);
      g.lineStyle(5, 0x3333FF);
      g.lineTo(cuebot.x+v.x, cuebot.y+v.y);
  }


  public function onKeyDown(e) {

    switch(e.keyCode) {
    case 66: // b
      blurFilter.blurX = 10;
      // trace("blur!");
    case 80: // p
      paused ? resume() : pause();
    case 84: // t
      var ct = new flash.geom.ColorTransform(Math.random(), Math.random(), Math.random());
      bg.transform.colorTransform = ct;
    case 48,49,50,51,52,53,54,55,56,57:
      resetWorld(e.keyCode - 48);
    default:
      if (keyboardControl) {
	switch(e.keyCode) {
	case Keyboard.UP:
	  kick(cuebot, shepClipVector().mult(5));
	case Keyboard.LEFT:
	  shepClip.rotation -= 15;
	case Keyboard.RIGHT:
	  shepClip.rotation += 15;
	default:
	  resetWorld(currentLevel);
	}
      } else {
	resetWorld(currentLevel);
      }
    }
  }

  public function onClick(e) {
    if (! (done || paused)) {
      kick(cuebot, calcVector(50));
    }
  }

  public function kick(body:phx.Body, howHard:phx.Vector) {
    var oldv = body.v;
    body.setSpeed(oldv.x + howHard.x, oldv.y + howHard.y);
    world.activate(body);
  }


  public function loadLevel(which:Int) {
    currentLevel = which;
    var url = "levels/000" + which + ".svg";
    loader = new URLLoader(new URLRequest(url));
    loader.addEventListener("complete", onLevelLoad);

    clearClip(fg);

    var fgc:MovieClip;
    switch (which) {
    case 0: fgc = new FG0000(); showPhysics = true;
    case 1: fgc = new FG0001(); showPhysics = true;
    case 2: fgc = new FG0002(); showPhysics = true;
    case 3: fgc = new FG0003(); showPhysics = true;
    case 4: fgc = new FG0004(); showPhysics = true;
    case 5: fgc = new FG0005(); showPhysics = true;
    case 6: fgc = new FG0006(); showPhysics = true;
    case 7: fgc = new FG0007(); showPhysics = true;
    case 8: fgc = new FG0008(); showPhysics = true;
    case 9: fgc = new FG0009(); showPhysics = true;
    default:
      fgc = new MovieClip();
      showPhysics = true;
    }
    fg.addChild(fgc);
  }


  public function addPocket(cx:Float, cy:Float, ?code:Int) {
    // the zone is really just here for debugging purposes
    // it also makes the pocket look like a square so it's
    // easier to distingquish from the small balls
    var zone = new phx.Body(0, 0);
    zone.addShape(phx.Shape.makeBox(60, 60, cx-30, cy-30, 
				    new phx.Material(0,0,0)));
    world.addBody(zone);
    
    var pocket = new Pocket(cx, cy);
    pocket.code = code;
    pocket.addShape(new phx.Circle(15, new phx.Vector(0, 0),
				   bouncyWall));
    world.addBody(pocket);
    var pclip = centerClip(new PocketClip());
    pclip.x = cx;
    pclip.y = cy;

    if (code > 0) {
      pclip.filters = [socketGlow];
    }

    mg.addChild(pclip);
    pockets.push(pocket);
    return pocket;
  }

  public function addPolyXml(poly:Xml) {
      var points = StringTools.trim(poly.get("points"));
      var vertices:Array<phx.Vector> = [];

      if (points != null) {
	for (pair in points.split(" ")) {
	  
	  var xy = pair.split(",");
	  var x = Std.parseFloat(xy[0]);
	  var y = Std.parseFloat(xy[1]);
	  vertices.push(new phx.Vector(x, y));
	}


	var origin = new phx.Vector(0,0);
	var mat = poly.get("fill") == "#FF00FF" ? floatyWall : bouncyWall;

	var p = new phx.Polygon(vertices, origin, mat);


	// revese the vertices, or physaxe will screw up the area
	// calculations, and make it a static shape.
	if (p.area < 0) {
	  vertices.reverse();
	  p = new phx.Polygon(vertices, origin, mat);
	}

	
	// trace("area of p is: " + p.area);
	
	var b = new phx.Body(0,0);
	b.addShape(p);
	world.addBody(b);
	world.activate(b);
      }
  }
  
  public function addSpinner(cx:Float, cy:Float, w:Float, h:Float) {
    var shape = phx.Shape.makeBox(w, h, -(w/2), -(h/2), bouncyWall);
    var b = new phx.Body(cx,cy);
    b.addShape(shape);
    world.addBody(b);
    spinners.push(b);
  }

  public function addDoor(shape:phx.Shape, clip:MovieClip) {
    var door = new BodyClip(new phx.Body(0, 0), clip);
    door.body.addShape(shape);
    world.addBody(door.body);
    doors.push(door);
  }

  public function onLevelLoad(e:Event) {
    svg = Xml.parse(loader.data).firstElement();

    // trace("level loaded.");

    var green = "#00FF00";
    var red = "#FF0000";
    var blue = "#0000FF";
    var cyan = "#00FFFF";
    var darkCyan = "#009999";

    spinners = [];

    doors = [];

    for (rect in svg.elementsNamed("rect")) {

      var x = Std.parseFloat(rect.get("x"));
      var y = Std.parseFloat(rect.get("y"));
      var w = Std.parseFloat(rect.get("width"));
      var h = Std.parseFloat(rect.get("height"));
      var cx = x + (w/2);
      var cy = y + (h/2);

      var shape = phx.Shape.makeBox(w, h, x, y, bouncyWall);
      
      var fill = rect.get("fill");
      if (fill == green) {
	addPocket(cx, cy);

      } else if (fill == cyan) {
	addPocket(cx, cy, 1);

      } else if (fill == darkCyan) {
	addDoor(shape, null);

      } else if (fill == blue) {
	addSpinner(cx, cy, w, h);

      } else {
	addWall(shape);
      }
    }

    for (poly in svg.elementsNamed("polygon")) {
      addPolyXml(poly);
    }

    smallballs = [];
    for (circ in svg.elementsNamed("circle")) {
      var cx = Std.parseFloat(circ.get("cx"));
      var cy = Std.parseFloat(circ.get("cy"));
      
      // green is the hero
      if (circ.get("fill") == green) {
	cuebot.setPos(cx, cy);
      }

      // anything else is a fuseball
      
      else {
	var smallball = new phx.Body(cx, cy);
	smallball.addShape(new phx.Circle(15, new phx.Vector(0, 0), 
					  robotParts));
	world.addBody(smallball);
	var bodyclip = makeBallClip(smallball);
	smallballs.push(bodyclip);
	mg.addChild(bodyclip.clip);

	if (circ.get("fill") != red) {
	  bodyclip.clip.filters = [socketGlow];
	  bodyclip.code = 1; // just some arbitrary code @TODO: match keys and doors
	}

      } 
    } // circles

    // shep is at the very end so he goes on top
    mg.addChild(shepClip);

    clock.startTimer(timeLimit);
    done = false;
  }


  public function makeBallClip(body:phx.Body):BodyClip {
    return new BodyClip(body, centerClip(new BallClip()));
  }


  public function offsetClip(clip:MovieClip, x:Float, y:Float):MovieClip {
    var holder = new MovieClip();
    holder.addChild(clip);
    clip.x = x;
    clip.y = y;
    return holder;
  }

  public function centerClip(clip):MovieClip {
    return offsetClip(clip, -clip.width/2, -clip.height/2);
  }


  static function main() {
    var parent = flash.Lib.current;
    var game = new Game1(parent);
  }


  function clearClip(clip:MovieClip) {
    while (clip.numChildren > 0) {
      clip.removeChildAt(0);
    }
  }


  // these two are meant to be called from flex:

  public function pause() {
    paused = true;
    starfield.paused = true;
  }
  
  public function resume() {
    paused = false;
    starfield.paused = false;
    clock.resume();
  }

  public function restart() {
    resetWorld(currentLevel);    
  }

  public function startLevel(n:Int){
    resetWorld(n);
  } 

  // these talk back to flex:

  function onWin() {
    done = true;
    if (winCallback != null) {
      winCallback(clock.timeCount);
    } else {
      // trace("you won!");
    }
  }

  function onLoss() {
    done = true;
    if (loseCallback != null) {
      loseCallback();
    } else {
      // trace("time ran out!");
    }
  }

}
