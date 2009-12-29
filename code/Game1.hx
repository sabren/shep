
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
import flash.net.URLLoader;
import flash.net.URLRequest;

class Game1
{

  var world : phx.World;
  var root : MovieClip;

  var bouncyWall : phx.Material;
  var smallball : phx.Body;
  var cuebot : phx.Body;
  var pocket : phx.Body;

  var done : Bool;

  var loader : URLLoader;
  var svg : Xml;

  public function new(root:MovieClip) {
    this.root = root;

    bouncyWall = new phx.Material(1, 2, 500);
    resetWorld();

    var stage = root.stage;
    stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    stage.addEventListener(MouseEvent.MOUSE_DOWN, onClick);
    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown );

  }

  public function onEnterFrame(e) {
    if (! done) {
      updateWorld();
      checkForWin();
      drawWorld();
    }
  }

  public function resetWorld() {

    var broadphase = new phx.col.SortedList();
    var boundary = new phx.col.AABB(-2000, -2000, 2000, 2000);
    world = new phx.World(boundary, broadphase);

    cuebot = new phx.Body(10, 10);
    cuebot.addShape(new phx.Circle(20, new phx.Vector(0, 0)));
    world.addBody(cuebot);

    pocket = new phx.Body(450, 50);
    pocket.addShape(new phx.Circle(10, new phx.Vector(37.5, 37.5),
				   new phx.Material(0.002, 2000, 2000)));
    world.addBody(pocket);

    var zone = new phx.Body(450, 50);
    zone.addShape(phx.Shape.makeBox(75, 75, 450, 50, 
    				    new phx.Material(0,0,0)));
    world.addBody(zone);

    smallball = new phx.Body(500, 500);
    smallball.addShape(new phx.Circle(10, new phx.Vector(0, 0)));
    world.addBody(smallball);
    

    var w = 800;
    var h = 575;
    var b = 25; // border
    
    addWall(phx.Shape.makeBox(w, b, 0, -b)); // top
    addWall(phx.Shape.makeBox(10, h, -b, 0)); // left
    addWall(phx.Shape.makeBox(10, h, w, 0)); // right
    addWall(phx.Shape.makeBox(w, b, 0, h)); // bottom
    
    haxe.Log.clear();
    loadLevel();

  }

  function addWall(shape:phx.Shape) {
    shape.material = bouncyWall;
    world.addStaticShape(shape);
  }

  function updateWorld() {
    world.step(1, 25);
  }

  function checkForWin() {

    for (a in world.arbiters) {
      if (a.sleeping) continue;
      if ((a.s1.body == pocket && a.s2.body == cuebot) ||
	  (a.s2.body == pocket && a.s1.body == cuebot)) {
	trace("you won!");
	done = true;
      }
    }
  }

  function drawWorld() {
    var g = root.graphics;
    g.clear();
    var fd = new phx.FlashDraw(g);
    fd.boundingBox.line = 0x000000;
    fd.contact.line = 0xFF0000;
    fd.sleepingContact.line = 0xFF00FF;
    // fd.staticShape.fill = 0x00FF00;
    fd.drawCircleRotation = true;
    fd.drawWorld(world);
    drawVector(g);
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
    g.moveTo(cuebot.x, cuebot.y);
    g.lineStyle(5, 0x3333FF);
    g.lineTo(cuebot.x+v.x, cuebot.y+v.y);
  }



  public function onKeyDown(e) {
    resetWorld();
  }

  public function onClick(e) {
    
    var kick = calcVector(150);
    var oldv = cuebot.v;
    cuebot.setSpeed(oldv.x + kick.x, oldv.y + kick.y);
    world.activate(cuebot);
  }


  public function loadLevel() {
    var url = "levels/0001.svg";
    loader = new URLLoader(new URLRequest(url));
    loader.addEventListener("complete", onLevelLoad);
  }

  public function onLevelLoad(e:Event) {
    svg = Xml.parse(loader.data).firstElement();

    trace("level loaded.");
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

	var p = new phx.Polygon(vertices, new phx.Vector(1,1),
				bouncyWall);


	// revese the vertices, or physaxe will screw up the area
	// calculations, and make it a static shape.
	if (p.area < 0) {
	  vertices.reverse();
	  p = new phx.Polygon(vertices, new phx.Vector(1,1),
				  bouncyWall);
	}

	
	// trace("area of p is: " + p.area);
	
	var b = new phx.Body(50,50);
	b.addShape(p);
	world.addBody(b);
	world.activate(b);
      }
    }
    done = false;
  }

  static function main() {
    var root = flash.Lib.current;
    var game = new Game1(root);
  }

}
