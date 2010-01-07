
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
import feffects.Tween;
import feffects.easing.Bounce;

class ClockFont extends flash.text.Font {}

class BorderClip extends MovieClip {}

class BG0000 extends MovieClip {}
class BG0001 extends MovieClip {}
class BG0002 extends MovieClip {}
class BG0003 extends MovieClip {}
class BG0004 extends MovieClip {}
class BG0005 extends MovieClip {}
class BG0006 extends MovieClip {}
class BG0007 extends MovieClip {}
class BG0008 extends MovieClip {}
class BG0009 extends MovieClip {}

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
class GlowClip extends MovieClip {}
class BallClip extends MovieClip {}
class PocketClip extends MovieClip {}
class DoorClip extends MovieClip {}
class SpinnerClip extends MovieClip {}
class RedBallClip extends MovieClip {}
class RedPocketClip extends MovieClip {}
class CargoClip extends MovieClip {}
class CrateClip extends MovieClip {}

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
  static var border = 25;

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
  var glowClip : MovieClip;
  var showPhysics : Bool;
  var smallballs : Array<BodyClip>;
  var doors : Array<BodyClip>;
  var spinners : Array<BodyClip>;
  var floaters : Array<BodyClip>;
  var starfield : StarField;

  public var winCallback : Float -> Void;
  public var loseCallback : Void -> Void;

  public function new(parent:Sprite) {

    this.parent = parent;

    smallballs = [];
    pockets = [];
    doors = [];
    floaters = [];

    socketGlow = new GlowFilter(0xFF0000, 1, 3.5, 3.5, 4);
    // phx.Material(restitution, friction, density );
    floatyWall = new phx.Material(0.5, 2, 100);
    bouncyWall = new phx.Material(1, 2, Math.POSITIVE_INFINITY);
    robotParts = new phx.Material(0.5, 20, 20);

#if !EXTERNAL_STARFIELD
    starfield = new StarField(800,575);
    parent.addChild(starfield);
#end

    bg = new MovieClip();
    blurFilter = new BlurFilter(0,0);
    bg.filters = [blurFilter];
    parent.addChild(bg);

    mg = new MovieClip();
    parent.addChild(mg);

    fg = new MovieClip();
    //fg.x = border; fg.y = border;
    parent.addChild(fg);

    parent.addChild(new BorderClip());

    clock = new FlashClock();

    physaxeLayer = new MovieClip();
    physaxeLayer.alpha = 0.5;
    parent.addChild(physaxeLayer);

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

    clockText.autoSize = TextFieldAutoSize.CENTER;
    clockText.x = (400 - clockText.textWidth/2)-2;

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
      updateClock();

      // these have to come after the clock updates, or there
      // will be trouble with restarting after a timeout
      checkForWin();
      checkForLoss();

      drawWorld();
    }
  }


  public function updateClock() {
    clockText.text = clock.toString();

    var tl = clock.timeLeft();
    if (tl <= 30) {
      // red alert!
      var v = (1 + Math.sin(clock.timeLeft()*5)) * 0.40;
      var ct = new flash.geom.ColorTransform(0.25+v, 0, 0);
      bg.transform.colorTransform = ct;
      mg.transform.colorTransform = new flash.geom.ColorTransform(1+v, 0.75, 0.75);
      fg.transform.colorTransform = new flash.geom.ColorTransform(0.75+v, 0.5, 0.5);
    } else if (currentLevel == 9 && Math.ceil((tl * 10)) % 10 == 0) {
      bg.transform.colorTransform = new flash.geom.ColorTransform(Math.random(), Math.random(), Math.random());
      mg.transform.colorTransform = new flash.geom.ColorTransform(Math.random()+0.25, Math.random()+0.25, Math.random()+0.25);
    }
  }

  public function resetWorld(level:Int) {

    done = true;
    
    // clear red alert / strobe
    bg.transform.colorTransform = new flash.geom.ColorTransform(1.00, 1.0, 1.0);
    mg.transform.colorTransform = new flash.geom.ColorTransform(1.00, 1.0, 1.0);
    fg.transform.colorTransform = new flash.geom.ColorTransform(1.00, 1.0, 1.0);
 
    var broadphase = new phx.col.SortedList();
    var boundary = new phx.col.AABB(-2000, -2000, 2000, 2000);
    world = new phx.World(boundary, broadphase);

    clearClip(mg);

    cuebot = new phx.Body(10, 10);
    cuebot.addShape(new phx.Circle(20, new phx.Vector(0, 0), robotParts));
    world.addBody(cuebot);

    var png = new ShepClip();
    shepClip = centerClip(png);
    glowClip = new GlowClip();
    glowClip.x = -glowClip.width / 2;
    glowClip.y = png.y + png.height - glowClip.height + 5;
    glowClip.alpha = 0.5;
    shepClip.addChild(glowClip);

    var w = 800;
    var h = 575;
    var b = border;
    
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
      s.body.w = spinnerVelocity;
      s.body.t = spinnerTorque;
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

		//@TODO: multiple colored doors?
		if (pocket.code > 0) {
		  if (doors.length > 0)
		    openDoor(doors[0]);
		}
		break;
	      }
	    }
	  }
	}
      }
    }
  }

    
  var openingDoor:BodyClip;
  function openDoor(d:BodyClip) {
    doors.remove(d);
    world.removeBody(d.body);
    
    openingDoor = d;
    var tween = new Tween( d.clip.y, 
			   d.clip.y+d.clip.height, 
			   1000, Bounce.easeOut );
    tween.setTweenHandlers(slideDoor, onDoorOpen);
    tween.start();
  }

  function slideDoor(e:Float) {
    openingDoor.clip.y = e;
  }

  function onDoorOpen(e:Float) {
    doors.remove(openingDoor);
    mg.removeChild(openingDoor.clip);
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

    for (s in spinners) {
      s.clip.rotation = rad2deg(s.body.a);
    }

    for (s in floaters) {
      s.clip.x = s.body.x;
      s.clip.y = s.body.y;
      s.clip.rotation = rad2deg(s.body.a);
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
    // bg.x = (blurFilter.blurX / 2.5); // parallax
    bg.filters = [blurFilter];

    var fgBlur = new BlurFilter();
    fgBlur.blurX = blurFilter.blurX / 2;
    fgBlur.blurY = blurFilter.blurY / 2;
    fg.filters = [fgBlur];

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

    /*
      g.moveTo(cuebot.x, cuebot.y);
      g.lineStyle(5, 0x3333FF);
      g.lineTo(cuebot.x+v.x, cuebot.y+v.y);
    */
  }


  public function onKeyDown(e) {

    switch(e.keyCode) {
    case 66: // b
      blurFilter.blurX = 10;
      // trace("blur!");
    case 68: // d = draw physics
      showPhysics = ! showPhysics;
    case 79:
      if (doors.length > 0) {
	openDoor(doors[0]);
	doors = [];
      }
    case 80: // p
      paused ? resume() : pause();
    case 82: // r = red alert
      clock.startTimer(30);
    case 84: // t
      bg.transform.colorTransform = new flash.geom.ColorTransform(Math.random(), Math.random(), Math.random());
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

#if PACK_LEVELS
    switch (which) {
    case 0: parseSVG(LevelPack.svg0000);
    case 1: parseSVG(LevelPack.svg0001);
    case 2: parseSVG(LevelPack.svg0002);
    case 3: parseSVG(LevelPack.svg0003);
    case 4: parseSVG(LevelPack.svg0004);
    case 5: parseSVG(LevelPack.svg0005);
    case 6: parseSVG(LevelPack.svg0006);
    case 7: parseSVG(LevelPack.svg0007);
    case 8: parseSVG(LevelPack.svg0008);
    case 9: parseSVG(LevelPack.svg0009);
    default:
    }
#else
    var url = "levels/000" + which + ".svg";
    loader = new URLLoader(new URLRequest(url));
    loader.addEventListener("complete", onSVGRequest);
#end

    clearClip(fg);
    clearClip(bg);

    var fgc:MovieClip;
    var bgc:MovieClip;

    switch (which) {
    case 0: fgc = new FG0000(); bgc = new BG0000();
    case 1: fgc = new FG0001(); bgc = new BG0001();
    case 2: fgc = new FG0002(); bgc = new BG0002();
    case 3: fgc = new FG0003(); bgc = new BG0003();
    case 4: fgc = new FG0004(); bgc = new BG0004();
    case 5: fgc = new FG0005(); bgc = new BG0005();
    case 6: fgc = new FG0006(); bgc = new BG0006();
    case 7: fgc = new FG0007(); bgc = new BG0007();
    case 8: fgc = new FG0008(); bgc = new BG0008();
    case 9: fgc = new FG0009(); bgc = new BG0009();
    default:
      fgc = new MovieClip();
      bgc = new MovieClip();
    }
    bg.addChild(bgc);
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
    var pclip:MovieClip;

    if (code > 0) {
      pclip = centerClip(new RedPocketClip());
      pclip.filters = [socketGlow];
    } else {
      pclip = centerClip(new PocketClip());
    }

    pclip.x = cx;
    pclip.y = cy;


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



	// transpose points to origin = center
	var c = findCenter(vertices);
	for (i in 0 ... vertices.length) {
	  vertices[i] = vertices[i].minus(c);
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

	var b = new phx.Body(c.x, c.y);
	b.addShape(p);

	if (mat == floatyWall) {
	  var clip:MovieClip;
	  if (vertices.length == 8) {
	    clip = centerClip(new CargoClip());
	  } else {
	    clip = centerClip(new CrateClip());
	  }
	  clip.x = c.x; clip.y = c.y;
	  floaters.push(addBodyClip(b, clip));

	} else {
	  world.addBody(b);
	  world.activate(b);
	}
      }
  }
  

  public function findCenter(vertices:Array<phx.Vector>) {
    var avg = new phx.Vector(0,0);
    for (v in vertices) {
      avg = avg.plus(v);
    }
    return avg.mult(1 / vertices.length);
  }

  public function addBodyClip(body, clip) : BodyClip {
    var bc = new BodyClip(body, clip);
    world.addBody(body);
    mg.addChild(clip);
    return bc;
  }

  public function addSpinner(cx:Float, cy:Float, w:Float, h:Float) {

    var sc = centerClip(new SpinnerClip());
    sc.x = cx; sc.y = cy;

    // hard coded shape because of the sprite
    var shape = phx.Shape.makeBox(15, 175, -7.5, -87.5, bouncyWall);
    var body = new phx.Body(cx, cy);
    body.addShape(shape);
    if (w > h) {
      body.a = deg2rad(-90);
    }

    spinners.push(addBodyClip(body, sc));
  }

  public function addDoor(shape:phx.Shape, clip:MovieClip, cx, cy) {
    var body = new phx.Body(0, 0);
    body.addShape(shape);
    clip.x = cx; clip.y = cy;
    doors.push(addBodyClip(body, clip));
  }

  public function onSVGRequest(e:Event) {
    parseSVG(loader.data);
  }

  public function parseSVG(xml_text:String) {
    svg = Xml.parse(xml_text).firstElement();

    // trace("level loaded.");

    var green = "#00FF00";
    var red = "#FF0000";
    var blue = "#0000FF";
    var cyan = "#00FFFF";
    var darkCyan = "#009999";

    spinners = [];
    floaters = [];
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
	addDoor(shape, new DoorClip(), x, y);

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
	var bodyclip:BodyClip;
    
	if (circ.get("fill") != red) {
	  bodyclip = new BodyClip(smallball, centerClip(new RedBallClip()));
	  bodyclip.clip.filters = [socketGlow];
	  bodyclip.code = 1; // just some arbitrary code @TODO: match keys and doors
	} else {
	  bodyclip = new BodyClip(smallball, centerClip(new BallClip()));
	}

	smallballs.push(bodyclip);
	mg.addChild(bodyclip.clip);
      } 
    } // circles

    // shep is at the very end so he goes on top
    mg.addChild(shepClip);

    clock.startTimer(timeLimit);
    done = false;
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
