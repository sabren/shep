
import flash.events.Event;
import flash.display.MovieClip;
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

class DsDigiFont extends flash.text.Font {}
class BG0001 extends MovieClip {}
class FG0001 extends MovieClip {}
class ShepClip extends MovieClip {}
class BallClip extends MovieClip {}
class PocketClip extends MovieClip {}

class BodyClip {
  public var clip : MovieClip;
  public var body : phx.Body;
  public function new(body, clip) {
    this.body = body;
    this.clip = clip;
  }
}


class Game1
{

  var world : phx.World;
  var root : MovieClip;

  var bouncyWall : phx.Material;
  var robotParts : phx.Material;

  var pockets : Array<phx.Body>;
  var cuebot : phx.Body;

  var done : Bool;

  var loader : URLLoader;
  var svg : Xml;

  var clock:FlashClock;
  var clockText:TextField;

  var physaxeLayer : MovieClip;

  var currentLevel : Int;
  var bg : MovieClip;
  var mg : MovieClip;
  var fg : MovieClip;
  static var blurAmount : Int = 10;
  var blurFilter : BlurFilter;

  var shepClip : MovieClip;
  var showPhysics : Bool;
  var smallballs : Array<BodyClip>;

  public function new(root:MovieClip) {
    this.root = root;
    var stage = root.stage;
    
    smallballs = [];
    pockets = [];

    bouncyWall = new phx.Material(1, 2, Math.POSITIVE_INFINITY);
    robotParts = new phx.Material(0.5, 20, 20);

    bg = new BG0001();
    blurFilter = new BlurFilter(0,0);
    bg.filters = [blurFilter];
    stage.addChild(bg);

    physaxeLayer = new MovieClip();
    stage.addChild(physaxeLayer);

    mg = new MovieClip();
    stage.addChild(mg);

    fg = new MovieClip();
    stage.addChild(fg);

    clock = new FlashClock();

    var ds = new DsDigiFont();
    var fmt = new TextFormat(ds.fontName, 25, 0xFF0000);


    clockText = new TextField();
    clockText.embedFonts = true;
    clockText.x = 400;
    clockText.y = 0;
    clockText.antiAliasType = AntiAliasType.ADVANCED;
    clockText.background = true;
    clockText.backgroundColor = 0x000000;
    clockText.multiline = true;
    clockText.autoSize = TextFieldAutoSize.LEFT;
    clockText.visible = true;

    clockText.defaultTextFormat = fmt;
    clockText.setTextFormat(fmt);
    stage.addChild(clockText);

    updateClock();
    done = true;

    resetWorld(1);

    // save this to the end so world is ready to go for first frame event
    stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    stage.addEventListener(MouseEvent.MOUSE_DOWN, onClick);
    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown );
    // nothing below here should edit the world!
  }

  public function onEnterFrame(e) {
    if (! done) {
      updateWorld();
      checkForWin();
      drawWorld();
      updateClock();
    }
  }

  public function updateClock() {
    clockText.text = clock.toString();
  }

  public function resetWorld(level:Int) {

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
    
    haxe.Log.clear();
    loadLevel(level);

  }

  function addWall(shape:phx.Shape) {
    shape.material = bouncyWall;
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


  }

  function checkForWin() {

    for (pocket in pockets) {
      for (arb in pocket.arbiters) {
	var shape = (arb.s1.body == pocket) ? arb.s2 : arb.s1;
	if (shape.body == cuebot) {
	  if (smallballs.length == 0) {
	    trace("you won!");
	    done = true;
	  }
	} else {
	  for (b in smallballs) {
	    if (shape.body == b.body) {
	      smallballs.remove(b);
	      mg.removeChild(b.clip);
	      world.removeBody(shape.body);
	      break;
	    }
	  }
	}
      }
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
    bg.filters = [blurFilter];
    
    shepClip.x = cuebot.x;
    shepClip.y = cuebot.y;
    
  }


  function calcVector(r:Int) {
    var x1 = cuebot.x;
    var y1 = cuebot.y;
    
    var x2 = root.mouseX;
    var y2 = root.mouseY;

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
    return  180 / Math.PI * rad;
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
    var v = calcVector(r);
    
    if (v.x == 0) {
      shepClip.rotation = v.y <= 0 ? 0 : 180;
    } else {
      var slope = v.y / v.x;
      shepClip.rotation = 90 + rad2deg( Math.atan(slope));
      if (v.x < 0)
	shepClip.rotation += 180;
    }

    g.moveTo(cuebot.x, cuebot.y);
    g.lineStyle(5, 0x3333FF);
    g.lineTo(cuebot.x+v.x, cuebot.y+v.y);

    // cotangent

  }



  public function onKeyDown(e) {

    switch(e.keyCode) {
      
    case 66: // b
      //bg.filters = [new BlurFilter(10)];
      blurFilter.blurX = 10;
      //      bg.filters = [blurFilter];
      trace("blur!");
    case 48,49,50,51,52,53,54,55,56,57:
      resetWorld(e.keyCode - 48);
    default:
      resetWorld(currentLevel);
    }

  }

  public function onClick(e) {
    
    var kick = calcVector(50);
    var oldv = cuebot.v;
    cuebot.setSpeed(oldv.x + kick.x, oldv.y + kick.y);
    world.activate(cuebot);
  }


  public function loadLevel(which:Int) {
    currentLevel = which;
    var url = "levels/000" + which + ".svg";
    loader = new URLLoader(new URLRequest(url));
    loader.addEventListener("complete", onLevelLoad);

    clearClip(fg);
    if (which == 1) {
      var loadit = new flash.display.Loader();
      fg.addChild(new FG0001());
      showPhysics = false;
    } else {
      showPhysics = true;
    }
  }

  public function onLevelLoad(e:Event) {
    svg = Xml.parse(loader.data).firstElement();

    trace("level loaded.");


    for (rect in svg.elementsNamed("rect")) {
      var x = Std.parseFloat(rect.get("x"));
      var y = Std.parseFloat(rect.get("y"));
      var w = Std.parseFloat(rect.get("width"));
      var h = Std.parseFloat(rect.get("height"));
      var cx = x + (w/2);
      var cy = y + (h/2);
      
      
      // the zone is really just here for debugging purposes
      // it also makes the pocket look like a square so it's
      // easier to distingquish from the small balls
      var zone = new phx.Body(0, 0);
      zone.addShape(phx.Shape.makeBox(60, 60, cx-30, cy-30, 
				      new phx.Material(0,0,0)));
      world.addBody(zone);
      
      var pocket = new phx.Body(cx, cy);
      pocket.addShape(new phx.Circle(15, new phx.Vector(0, 0),
				     bouncyWall));
      world.addBody(pocket);
      var pclip = centerClip(new PocketClip());
      pclip.x = cx;
      pclip.y = cy;
      mg.addChild(pclip);
      pockets.push(pocket);
      
    }

    for (poly in svg.elementsNamed("polygon")) {

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

	var p = new phx.Polygon(vertices, origin, bouncyWall);


	// revese the vertices, or physaxe will screw up the area
	// calculations, and make it a static shape.
	if (p.area < 0) {
	  vertices.reverse();
	  p = new phx.Polygon(vertices, origin, bouncyWall);
	}

	
	// trace("area of p is: " + p.area);
	
	var b = new phx.Body(0,0);
	b.addShape(p);
	world.addBody(b);
	world.activate(b);
      }
    }

    smallballs = [];
    for (circ in svg.elementsNamed("circle")) {
      var cx = Std.parseFloat(circ.get("cx"));
      var cy = Std.parseFloat(circ.get("cy"));
      
      // red are little balls
      if (circ.get("fill") == "#FF0000") {
	var smallball = new phx.Body(cx, cy);
	smallball.addShape(new phx.Circle(15, new phx.Vector(0, 0), 
					  robotParts));
	world.addBody(smallball);
	var bodyclip = makeBallClip(smallball);
	smallballs.push(bodyclip);
	mg.addChild(bodyclip.clip);

      } 

      // green is the hero
      else if (circ.get("fill") == "#00FF00") {
	cuebot.setPos(cx, cy);
      }
    } // circles
    
    

    // shep is at the very end so he goes on top
    mg.addChild(shepClip);


    done = false;
    clock.startTimer(120);

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
    var root = flash.Lib.current;
    var game = new Game1(root);
  }


  function clearClip(clip:MovieClip) {
    while (clip.numChildren > 0) {
      clip.removeChildAt(0);
    }
  }


}
