import flash.display.Sprite;
import mt.deepnight.SpriteLibBitmap;
import mt.deepnight.Color;
import mt.deepnight.Lib;

class Entity {
	public static var ALL : Array<Entity> = new Array();
	public static var TOKILL : Array<Entity> = new Array();
	
	var mode				: Mode;
	var uid					: Int;
	var fx					: Fx;
	
	public var sprite		: BSprite;
	public var cd			: mt.Cooldown;
	
	public var cx			: Int;
	public var cy			: Int;
	public var xr			: Float;
	public var yr			: Float;
	public var dx			: Float;
	public var dy			: Float;
	public var xx			: Float;
	public var yy			: Float;
	public var frictX		: Float;
	public var frictY		: Float;
	public var radius		: Float;
	public var speed		: Float;
	public var dir			: Int;
	public var weight		: Float;
	var gravity				: Float;
	var ignoreColAbove		: Int;
	public var color		: Int;
	var bumperPower			: Float;
	
	public var outOfGame	: Bool;
	public var kickable		: Bool;
	public var killed		: Bool;
	public var stable		: Bool;
	public var repel		: Bool;
	var collides			: Bool;
	
	
	public function new() {
		mode = Mode.ME;
		fx = mode.fx;
		uid = Const.UID++;
		ALL.push(this);
		cd = new mt.Cooldown();

		bumperPower = 1.8;
		color = 0xFFFF00;
		ignoreColAbove = -1;
		stable = false;
		outOfGame = false;
		repel = true;
		killed = false;
		collides = true;
		kickable = false;
		weight = 1;
		frictX = frictY = 0.85;
		dir = 1;
		radius = Const.GRID*0.4;
		speed = 0.06;
		gravity = Const.GRAVITY;
		dx = dy = 0;
		setPos(5,5);
		
		sprite = new BSprite(mode.tiles);
		mode.dm.add(sprite, Const.DP_ENTITY);
		sprite.setCenter(0.5, 1);
	}
	
	public function getCenter() {
		return {x:xx, y:yy-radius};
	}
	
	public function centerDistance(e:Entity) {
		var c = getCenter();
		var ce = e.getCenter();
		return mt.deepnight.Lib.distance(c.x, c.y, ce.x, ce.y);
	}
	
	public inline function atDistance(e:Entity, dist:Float) {
		var d = mt.deepnight.Lib.distanceSqr(xx,yy, e.xx,e.yy);
		if( d<=dist*dist )
			return Math.sqrt(d)<=dist;
		else
			return false;
	}
		
	public inline function rnd(min,max,?sign) {
		return mt.deepnight.Lib.rnd(min,max,sign);
	}
	public inline function irnd(min,max,?sign) {
		return mt.deepnight.Lib.irnd(min,max,sign);
	}
	
	public function destroy() {
		if( !killed )
			TOKILL.push(this);
		killed = true;
	}
	
	public function unregister() {
		ALL.remove(this);
		sprite.parent.removeChild(sprite);
	}
	
	
	function onLand() {
		dy = 0;
		stable = true;
		ignoreColAbove = -1;
	}
	
	
	function onDie() {
	}
	
	public inline function hasCollision(cx,cy) {
		return collides && ( mode.level.hasHardCollision(cx,cy) || mode.level.hasSoftCollision(cx,cy) );
	}
	
	public inline function hasHardCollision(cx,cy) {
		return collides && mode.level.hasHardCollision(cx,cy);
	}
	
	public inline function hasSoftCollision(cx,cy) {
		return collides && mode.level.hasSoftCollision(cx,cy);
	}
	
	public function setPos(x,y) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 1;
		updateScreenCoords();
	}
	
	public function setPosPixel(x,y) {
		xx = x;
		yy = y;
		cx = Math.round(xx/Const.GRID);
		cy = Math.round(yy/Const.GRID);
		xr = (xx-cx*Const.GRID) / Const.GRID;
		yr = (yy-cy*Const.GRID) / Const.GRID;
	}

	public function updateScreenCoords() {
		xx = (cx+xr)*Const.GRID;
		yy = (cy+yr)*Const.GRID;
	}
	
	public function onTouch(e:Entity) {
	}
	

	public function onHitWall() {
		dx = 0;
	}
	
	function onTeleport() {
	}
	
	public function onKick(e:Entity) {
	}
	
	public function update() {
		cd.update();
		
		if( !outOfGame ) {
			// Repel
			if( repel )
				for(e in Entity.ALL)
					if( e!=this && e.repel ) {
						var c1 = getCenter();
						var c2 = e.getCenter();
						var d = Lib.distance(c1.x, c1.y, c2.x, c2.y);
						if( d<=radius + e.radius ) {
							var a = Math.atan2(c2.y-c1.y, c2.x-c1.x);
							var pow = 0.05;
							var wr = weight/e.weight;
							onTouch(e);
							e.onTouch(this);
							dx += -Math.cos(a) * pow * (1/wr);
							dy += -Math.sin(a) * pow * (1/wr);
							e.dx += Math.cos(a) * pow * wr;
							e.dy += Math.sin(a) * pow * wr;
						}
					}
				
			// Gravity
			if( (yr<1 || !hasCollision(cx,cy+1)) )
				stable = false;
			if( !stable )
				dy += gravity;
				
			// X component
			xr+=dx;
			dx*=frictX;
			if( Math.abs(dx)<=0.001 )
				dx = 0;
			if( xr<=0.4 && hasHardCollision(cx-1, cy) ) {
				xr = 0.4;
				onHitWall();
			}
			if( xr>=0.6 && hasHardCollision(cx+1, cy) ) {
				xr = 0.6;
				onHitWall();
			}
			while( xr<0 ) {
				cx--;
				xr++;
			}
			while( xr>1 ) {
				cx++;
				xr--;
			}
			
			// Y component
			yr+=dy;
			dy*=frictY;
			if( yr<=0.7 && hasHardCollision(cx,cy-1) ) {
				dy = 0;
				yr = 0.7;
			}
			if( yr>=1 && (hasHardCollision(cx,cy+1) || hasSoftCollision(cx,cy+1) && cy>ignoreColAbove) ) {
				yr = 1;
				if( !stable )
					onLand();
			}
					
			while( yr<0 ) {
				cy--;
				yr++;
			}
			while( yr>1 ) {
				cy++;
				yr--;
			}
			if( cy>=ignoreColAbove )
				ignoreColAbove = -1;
				
			// Graphical update
			updateScreenCoords();
			sprite.x = Std.int(xx);
			sprite.y = Std.int(yy);
			sprite.scaleX = dir;
		
			// Bumpers
			for(b in mode.level.bumpers)
				if( cx==b.cx && (cy==b.cy || cy==b.cy-1) && !cd.hasSet("bumper", 10) ) {
					dx *= 0.4;
					dy = -bumperPower;
					Mode.SBANK.bumper01().play();
					fx.bumperActivated(xx,yy);
				}
		
			// Teleport
			var overTeleporter = false;
			for(t in mode.level.teleports)
				if( cx==t.cx && cy==t.cy ) {
					overTeleporter = true;
					if( !cd.has("teleport") )  {
						var pt = mode.level.getTeleportDestination(t.cx, t.cy);
						outOfGame = true;
						cd.set("teleport", 9999);
						fx.teleportDirection((t.cx+0.5)*Const.GRID, (t.cy+0.5)*Const.GRID, (pt.cx+0.5)*Const.GRID, (pt.cy+0.5)*Const.GRID, color);
						Mode.SBANK.teleport01().play();
						mode.delayer.add(function() {
							outOfGame = false;
							setPos(pt.cx, pt.cy);
							onTeleport();
							fx.teleportArrival(xx, yy-radius, color);
						}, 200);
					}
				}
			if( !overTeleporter && cd.get("teleport")>=99 )
				cd.unset("teleport");
				//cd.set("teleport", 30);
		}
		
		sprite.visible = !outOfGame;
	}
	
}
