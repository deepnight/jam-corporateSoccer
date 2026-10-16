import flash.display.BlendMode;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

import mt.deepnight.Particle;
import mt.deepnight.Lib;
import mt.deepnight.Color;

import Const;

class Fx {
	var mode			: Mode;
	var cd				: mt.Cooldown;
	var pt0				: flash.geom.Point;
	
	
	public function new() {
		mode = Mode.ME;
		cd = new mt.Cooldown();
		pt0 = new flash.geom.Point(0,0);
		Particle.LIMIT = #if debug 9999 #else 150 #end;
	}
	
	public function destroy() {
		Particle.clearAll();
	}
	
	public function register(p:Particle, ?blend:BlendMode) {
		mode.dm.add(p, Const.DP_FX);
		p.blendMode = blend==null ? BlendMode.ADD : blend;
	}

	inline function rnd(min:Float, max:Float, ?sign) { return Lib.rnd(min,max,sign); }
	inline function irnd(min, max,?sign) { return Lib.irnd(min,max,sign); }
	inline function rad(a) { return Lib.rad(a); }
	inline function deg(a) { return Lib.deg(a); }
	
	public function blood(x,y, dir) {
		for(i in 0...10) {
			var p = new Particle(x,y);
			p.drawBox(rnd(1,2), rnd(1,2), 0xFF2020, rnd(0.5, 1));
			p.dx = dir * rnd(0.5,6);
			p.dy = rnd(-3, -1);
			p.gy = Const.GRAVITY * rnd(3, 5);
			p.frictX = p.frictY = 0.96;
			p.dr = rnd(0,10);
			p.life = rnd(5, 20);
			p.filters = [ new flash.filters.GlowFilter(0x0, 0.5, 2,2,4) ];
			register(p, BlendMode.NORMAL);
		}
	}
	
	public function announce(str:String, ?col=0xFFFF00, ?left:Bool, ?duration=1000) {
		var lines = str.split("\n");
		var y = 0;
		for(line in lines) {
			var tf = mode.createField(line.toUpperCase(), col);
			mode.dm.add(tf, Const.DP_FX);
			tf.filters = [];
			tf.scaleX = 6;
			tf.scaleY = tf.scaleX;
			if( left==null ) {
				tf.x = Std.int( mode.buffer.width*0.5 - tf.width*0.5 );
				tf.y = Std.int( mode.buffer.height*0.5 - (lines.length*0.5)*60 - 26 + y*50 );
			}
			else {
				tf.x = left ? 0 : mode.buffer.width - tf.width;
				tf.y = -26 + y*50;
			}
			tf.blendMode = BlendMode.ADD;
			tf.filters = [ new flash.filters.GlowFilter(col, 0.8, 8,8,1) ];
			tf.alpha = 0;
			
			mode.tw.create(tf, "alpha", 1, TEaseIn, 200);
			mode.delayer.add(function() {
				mode.tw.create(tf, "alpha", 0, TEaseIn, 1300).onEnd = function() {
					tf.parent.removeChild(tf);
				}
			}, duration);
			y++;
		}
	}
	
	public function flashBang(col:Int, alpha:Float, ?duration=1000) {
		var s = new Sprite();
		mode.dm.add(s, Const.DP_FX);
		s.graphics.beginFill(col, alpha);
		s.graphics.drawRect(0,0, mode.buffer.width, mode.buffer.height);
		s.blendMode = BlendMode.ADD;
		mode.tw.create(s, "alpha", 0, duration).onEnd = function() {
			s.parent.removeChild(s);
		}
	}
	
	public function ballRespawn(x,y) {
		var p = new Particle(x,y);
		p.graphics.lineStyle(1, 0xFFFFFF, 0.6, flash.display.LineScaleMode.NONE);
		p.graphics.drawCircle(0,0, mode.ball.radius);
		p.scaleX = p.scaleY = 1;
		p.filters = [ new flash.filters.GlowFilter(0xFFFF00, 0.8, 8,8,1) ];
		p.life = 15;
		p.ds = 2;
		p.onUpdate = function() {
			p.ds*=0.92;
			//p.scaleX = p.scaleY*=0.85;
		}
		register(p);
	}
	
	public function kick(x,y, c) {
		var p = new Particle(x,y);
		//p.drawCircle(rnd(4,5), c, rnd(0.8,1));
		p.graphics.lineStyle(1, c, 1);
		p.graphics.drawCircle(0,0, 4);
		p.ds = 0.05;
		p.life = 0;
		//p.filters = [ new flash.filters.GlowFilter(c,0.4, 8,8, 2) ];
		register(p);
	}
	
	public function bigKick(x,y, c) {
		var p = new Particle(x,y);
		p.graphics.lineStyle(1, c, 1);
		p.graphics.beginFill(c, 0.6);
		p.graphics.drawCircle(0,0, 8);
		p.ds = 0.08;
		p.life = 0;
		register(p);
		
		for(i in 0...7) {
			var p = new Particle(x,y);
			p.drawBox(rnd(4,6), 1, c, rnd(0.3, 0.8));
			var a = rnd(0, 6.28);
			p.moveAng(a, rnd(1.3,2.5));
			p.rotation = deg(a);
			p.life = rnd(10, 15);
			p.ds = -0.03;
			p.frictX = p.frictY = 0.93;
			register(p);
		}
	}
	
	public function bumperActivated(x,y) {
		var c = 0xB179F7;
		var p = new Particle(x,y);
		p.drawCircle(6, c, 0.7);
		p.ds = 0.10;
		p.life = 0;
		register(p);
		for(i in 0...10) {
			var p = new Particle(x+rnd(0,2,true), y+rnd(0,2,true));
			p.drawBox(1, 2, c, rnd(0.3, 0.8));
			p.dy = -rnd(4,10);
			p.life = rnd(10, 20);
			p.frictX = p.frictY = 0.85;
			p.filters = [ new flash.filters.GlowFilter(c, 0.9, 4,4,3) ];
			register(p);
		}
	}
	
	public function goal(x,y, c) {
		var p = new Particle(x,y);
		p.drawCircle(8, c, 0.7);
		p.ds = 0.08;
		p.life = 0;
		register(p);

		for(i in 0...30) {
			var p = new Particle(x+rnd(0,2,true), y+rnd(0,2,true));
			p.drawBox(1, 1, c, rnd(0.3, 0.8));
			p.moveAng(rnd(1, 2, true), rnd(1,4));
			p.life = rnd(30, 60);
			p.frictX = p.frictY = 0.93;
			p.filters = [ new flash.filters.GlowFilter(c, 0.8, 4,4,2) ];
			register(p);
		}
	}
	
	public function goalZone(cx,cy, side) {
		if( cd.hasSet("goal"+[cx,cy], rnd(6,9)) )
			return;
		var x = (cx+0.5) * Const.GRID;
		var y = (cy+0.5) * Const.GRID;
		var p = new Particle(x + rnd(0,3,true), y + rnd(0,3,true));
		var col = side==0 ? 0xFF8484 : 0x0080FF;
		p.drawBox(1,1, col, rnd(0.2, 1));
		p.filters = [ new flash.filters.GlowFilter(col, 0.8, 4,4,3) ];
		p.dx = rnd(0, 0.3, true);
		p.dy = rnd(0, 0.5, true);
		p.life = rnd(10,30);
		p.frictX = p.frictY = rnd(0.90, 0.96);
		register(p);
	}
	
	public function teleporter(cx,cy) {
		if( cd.hasSet("teleporter"+[cx,cy], 5) )
			return;
		var x = (cx+0.5) * Const.GRID;
		var y = (cy+0.5) * Const.GRID;
		var p = new Particle(x + rnd(0,3,true), y + rnd(0,3,true));
		var col = 0xFFB300;
		p.drawBox(1,1, col, rnd(0.2, 1));
		p.filters = [ new flash.filters.GlowFilter(col, 0.8, 4,4,3) ];
		p.dx = rnd(0, 0.5, true);
		p.dy = rnd(0, 0.5, true);
		p.frictX = p.frictY = rnd(0.90, 0.96);
		register(p);
	}
	
	public function bumper(cx,cy) {
		if( cd.hasSet("bumper"+[cx,cy], 4) )
			return;
			
		var x = (cx+0.5) * Const.GRID;
		var y = (cy+1) * Const.GRID;
		var p = new Particle(x + rnd(0,2,true), y + rnd(0,2,true));
		var col = 0xFF48FF;
		p.alpha = 0;
		p.da = 0.2;
		p.drawBox(1,rnd(2,3), col, rnd(0.2, 1));
		p.filters = [ new flash.filters.GlowFilter(col, 0.4, 2,2,1) ];
		//p.dx = rnd(0, 0.5, true);
		p.life = rnd(5, 15);
		p.dy = -rnd(1,2);
		p.frictY = rnd(0.93, 0.96);
		p.onUpdate = function() {
			p.scaleY*=0.93;
		}
		register(p);
	}
	
	public function teleportArrival(x:Float,y:Float, c) {
		for(i in 0...30) {
			var a = rnd(0, 6.28);
			var d = 20;
			var p = new Particle(x-Math.cos(a)*d, y-Math.sin(a)*d);
			p.drawBox(1,1, c);
			p.moveAng( a, rnd(3,5));
			p.frictX = p.frictY = 0.9;
			p.life = rnd(10, 40);
			p.filters = [ new flash.filters.GlowFilter(c,1, 8,8,2) ];
			register(p);
		}
	}
	
	public function smoke(x,y) {
		for(i in 0...3) {
			var p = new Particle(x,y);
			p.drawCircle(rnd(1,2), 0x969696, rnd(0.2, 0.4));
			//p.drawBox(2,2, 0x969696, rnd(0.3, 0.6));
			p.dx = rnd(0.05, 0.3, true);
			p.dy = rnd(0, 0.2, true);
			p.gy = -0.02;
			p.life = rnd(10, 30);
			//p.ds = -0.05;
			p.frictX = p.frictY = rnd(0.92, 0.96);
			register(p, BlendMode.NORMAL);
		}
	}
	
	public function teleportDirection(fx:Float, fy:Float, tx:Float, ty:Float, c:Int) {
		var a = Math.atan2(ty-fy, tx-fx);
		var d = Lib.distance(fx,fy, tx,ty);
		for(i in 0...20) {
			var p = new Particle(fx+rnd(0,4,true), fy+rnd(0,4,true));
			p.drawBox(rnd(3,8), 1, c);
			p.life = rnd(3,8);
			var s = d/p.life;
			p.rotation = deg(a);
			p.moveAng(a, s*0.6);
			//p.frictX = p.frictY = rnd(0.96, 1);
			//p.filters = [ new flash.filters.GlowFilter(c,1, 4,4,2) ];
			p.filters =  [ new flash.filters.BlurFilter(4,4) ];
			register(p);
		}
	}
	
	public function jetpack(x,y) {
		for(i in 0...2) {
			var p = new Particle(x+rnd(0,2,true), y+rnd(0,1,true));
			p.drawBox(1, 1, 0xFFFF80);
			p.life = rnd(8,15);
			p.dx = rnd(0, 0.5, true);
			p.gy = Const.GRAVITY*2;
			p.frictX = p.frictY = 0.96;
			p.filters = [ new flash.filters.GlowFilter(0xFF6600,1, 4,4,2) ];
			register(p);
		}
	}
	
	public function update() {
		cd.update();
		Particle.update();
	}
}

