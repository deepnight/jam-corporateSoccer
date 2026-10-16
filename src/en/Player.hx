package en;

import mt.flash.Key;
import flash.ui.Keyboard;

import mt.deepnight.SpriteLibBitmap;
import mt.flash.Sfx;

class Player extends Entity {
	public static var ALL : Map<Int, Player> = new Map();
	
	var torso			: BSprite;
	var head			: BSprite;
	var body			: BSprite;
	var help			: flash.display.Bitmap;
	
	var id				: Int;
	var side			: Int;
	var keyLock			: Map<Int, Bool>;
	var kleft			: Array<Int>;
	var kright			: Array<Int>;
	var kjump			: Array<Int>;
	var kdown			: Array<Int>;
	var kkick			: Int;
	
	var jetpack			: Int;
	var jetSfx			: Sfx;
	
	
	public function new(i) {
		super();
		
		id = i;
		ALL.set(id, this);
		side = id%2;
		//charge = -1;
		speed = 0.07;
		setPos(10+i*5, 20);
		radius = 5.5;
		frictX = 0.80;
		frictY = 0.89;
		keyLock = new Map();
		
		jetSfx = Mode.SBANK.jetpack01();
		jetSfx.playLoop(999999, 0.03);
		jetSfx.mute();
		
		init();
		
		var pid = switch(id) {
			case 0 : 1;
			case 1 : 3;
			case 2 : 2;
			case 3 : 4;
			default : 0;
		}
		var tf = mode.createField("P"+(id+1), color, true);
		tf.filters = [
			new flash.filters.DropShadowFilter(1, 90, 0xffffff, 0.2, 0,0, 1, 1,true),
			new flash.filters.GlowFilter(0x0, 0.9, 2,2, 2),
		];
		help = mt.deepnight.Lib.flatten(tf,2);
		mode.dm.add(help, Const.DP_PLAYER);
		
		torso = mode.tiles.get("torso", side);
		sprite.addChild(torso);
		//mode.dm.add(torso, Const.DP_ENTITY);
		torso.setCenter(0.5, 1);
		
		head = mode.tiles.get("head", id);
		sprite.addChild(head);
		//mode.dm.add(head, Const.DP_ENTITY);
		head.setCenter(0.5, 1);
		
		body = mode.tiles.get("idle");
		body.setCenter(0.5, 1);
		sprite.addChild(body);
		
		playAnim("idle");
		mode.dm.add(sprite, Const.DP_PLAYER);
		
		sprite.filters = [ new flash.filters.GlowFilter(0x0,0.8, 2,2,4) ];
	}
	
	override function unregister() {
		super.unregister();
		ALL.remove(id);
	}
	
	public function playAnim(k:String) {
		//sprite.playAnim( (side==0 ? "red_" : "blue_") + k );
		body.playAnim(k);
	}
	
	override function onLand() {
		super.onLand();
		jetpack = Const.MAX_JETPACK;
	}
	
	function init() {
		color = side==0 ? 0xFF0000 : 0x0080FF;
		
		switch(id) {
			case 0 : // RED 1, player 1
				setPos(10, 20);
				kleft = [Keyboard.A, Keyboard.Q];
				kright = [Keyboard.D];
				kjump = [Keyboard.W, Keyboard.Z];
				kdown = [Keyboard.S];
				kkick = Keyboard.SHIFT;
				
			case 1 : // BLUE 1, player 3
				setPos(40, 20);
				kleft = [Keyboard.LEFT];
				kright = [Keyboard.RIGHT];
				kjump = [Keyboard.UP];
				kdown = [Keyboard.DOWN];
				kkick = Keyboard.CONTROL;
				
			case 2 : // RED 2, player 2
				setPos(10, 5);
				kleft = [Keyboard.J];
				kright = [Keyboard.L];
				kjump = [Keyboard.I];
				kdown = [Keyboard.K];
				kkick = Keyboard.Y;
					
			case 3 : // BLUE 2, player 4
				setPos(40, 5);
				kleft = [Keyboard.NUMPAD_4];
				kright = [Keyboard.NUMPAD_6];
				kjump = [Keyboard.NUMPAD_8];
				kdown = [Keyboard.NUMPAD_5, Keyboard.NUMPAD_2];
				kkick = Keyboard.PAGE_DOWN;
				
			default :
				kleft = [];
				kright = [];
				kjump = [];
				kdown = [];
		}
	}
	
	function isDown(klist:Array<Int>) {
		for(k in klist)
			if( Key.isDown(k) )
				return true;
				
		return false;
	}
	
	public function getBattleStrength() {
		return Math.sqrt(dx*dx + dy*dy);
	}
	
	
	function clash(e:Player) {
		if( cd.has("clash") || e.cd.has("clash") )
			return;
			
		cd.set("clash", 20);
		e.cd.set("clash", 20);
			
		var s1 = getBattleStrength();
		var s2 = e.getBattleStrength();
		var brute = s1>s2 ? this : e;
		var victim = s1>s2 ? e : this;
		
		fx.kick(victim.xx, victim.yy, brute.color);
	
		var cdir = brute.xx < victim.xx ? 1 : -1;
		if( !victim.cd.hasSet("immune", 30*5) ) {
			Sfx.playOne([ Mode.SBANK.hit04, Mode.SBANK.hit05, Mode.SBANK.hit06 ]);
			mode.delayer.add(function() {
				Sfx.playOne([ Mode.SBANK.hit01, Mode.SBANK.hit02, Mode.SBANK.hit03 ]);
			}, 40);
			fx.blood(victim.xx, victim.yy, cdir);
			victim.dx += cdir * rnd(1, 1.2);
			victim.dy -= rnd(0.2, 0.7);
			victim.stable = false;
			victim.cd.set("stun", 30*rnd(1.1, 1.3));
			brute.dx += -cdir * 0.5;
		}
		
	}
	
	function kick(e:Entity, powX:Float, powY:Float) {
		var base = 1;
		e.dx = dir * base * powX;
		e.dy = -base * powY;
		//var a = -0.5;
		//e.dx = Math.cos(a) * s * dir;
		//e.dy = Math.sin(a) * s;
		
		var c1 = getCenter();
		var c2 = e.getCenter();
		fx.kick(c2.x, c2.y, color);
		e.onKick(this);
	}
	
	override function onTouch(e:Entity) {
		super.onTouch(e);
		for(p in ALL) {
			if( e==p && p.side!=side ) {
				clash(p);
			}
		}
		//var b = mode.ball;
		//if( e==b && !b.hasOwner() && b.canBeCaught() ) {
			//trace("catch!");
			//b.setOwner(this);
		//}
	}
	
	function getKickablesAtReach() {
		if( mode.isOver )
			return new Array();
			
		var arr = new Array();
		for(e in Entity.ALL)
			if( !e.outOfGame && e.kickable && centerDistance(e)<=radius+e.radius )
				arr.push(e);
		return arr;
	}
	
	
	
	override function update() {
		var ball = mode.ball;
		
		if( cd.has("stun") ) {
			playAnim("stun");
			head.setGroup("headStun", id);
		}
		
		if( !outOfGame && !cd.has("stun") ) {
			if( head.groupName=="headStun" )
				head.setGroup("head", id);
				
			var s = speed;
			// Walk left
			if( isDown(kleft) ) {
				if( stable )
					playAnim("run");
				dx-=s;
				dir = -1;
				if( stable && ball.yy>=yy-radius && ball.yy<=yy+1 && ball.xx>=xx && ball.xx<=xx+radius+3 && !cd.hasSet("walkKick", 6) ) {
					Sfx.playOne([ Mode.SBANK.ball01, Mode.SBANK.ball02, Mode.SBANK.ball03 ]);
					kick(ball, Math.max(0.2, Math.abs(dx*2)), 0.3 );
				}
			}
			
			// Walk right
			if( isDown(kright) ) {
				if( stable )
					playAnim("run");
				dx+=s;
				dir = 1;
				if( stable && ball.yy>=yy-radius && ball.yy<=yy+1 && ball.xx>=xx-radius-3 && ball.xx<=xx && !cd.hasSet("walkKick", 6) ) {
					Sfx.playOne([ Mode.SBANK.ball01, Mode.SBANK.ball02, Mode.SBANK.ball03 ]);
					kick(ball, Math.max(0.2, Math.abs(dx*2)), 0.3 );
				}
			}
			
			if( stable && Math.abs(dx)>=0.2 && !cd.hasSet("smoke", 5) )
				fx.smoke(xx,yy);
			
			// Auto-braking
			if( !isDown(kleft) && !isDown(kright) ) {
				if( stable )
					playAnim("idle");
				dx*=0.6;
			}
				
				
			if( !stable )
				playAnim("jump");
				
			if( isDown(kjump) ) {
				var usingJetpack = false;
				if( stable ) {
					// Jumping
					dy = -1.05;
					stable = false;
					cd.set("jetpack", 5);
					Mode.SBANK.jump01().play(0.2);
				}
				else if( jetpack>0 && !cd.has("jetpack") ) {
					// Jetpacking
					jetpack--;
					usingJetpack = true;
					ignoreColAbove = -1;
					dy -= 0.08;
					fx.jetpack(xx-4*dir, yy-6);
					playAnim("jetpack");
					if( !cd.hasSet("jetpackSound", 15) )
						jetSfx.unmute();
				}
				// Kick UP
				if( !cd.hasSet("upKick", 4) )
					for(e in getKickablesAtReach()) {
						if( !usingJetpack )
							Sfx.playOne([ Mode.SBANK.ball01, Mode.SBANK.ball02, Mode.SBANK.ball03 ]);
						fx.kick(e.xx, e.yy, color);
						e.dx = dx*1.2;
						e.dy = -Math.abs(dy*1);
						e.onKick(this);
						if( usingJetpack ) {
							// Air control
							var tx = xx+dir*2;
							var ty = yy-3;
							var d = mt.deepnight.Lib.distance(tx, ty, e.xx, e.yy);
							if( d>=radius ) {
								var a = Math.atan2(e.yy-ty, e.xx-tx);
								e.setPosPixel(tx + Math.cos(a)*d*0.8, ty + Math.sin(a)*d*0.8);
							}
						}
					}
			}
			if( !isDown(kjump) && jetpack<Const.MAX_JETPACK )
				jetpack++;
				
			if( jetpack<=0 || !isDown(kjump) )
				jetSfx.mute();
			
			// Going down
			if( isDown(kdown) ) {
				if( stable && !hasHardCollision(cx,cy+1) ) {
					dy = -0.12;
					stable = false;
					ignoreColAbove = cy+1;
				}
				// Kick DOWN
				if( !cd.hasSet("downKick", 10) )
					for(e in getKickablesAtReach())
						if( !e.hasHardCollision(e.cx, e.cy+1) ) {
							fx.kick(e.xx, e.yy, color);
							e.dx = dx;
							e.dy += 0.3;
							e.ignoreColAbove = cy+1;
							e.onKick(this);
							Mode.SBANK.ball03(1);
						}
			}
			
			// Kick !
			if( Key.isDown(kkick) && !keyLock.get(kkick) && !cd.has("powerKick") ) {
				cd.set("upKick", 5);
				cd.set("downKick", 5);
				cd.set("powerKick", 20);
				fx.kick(xx+dir*5, yy-2, color);
				keyLock.set(kkick, true);
				var found = false;
				for(e in getKickablesAtReach()) {
					kick(e, 1.3, 0.4);
					fx.bigKick(e.xx, e.yy, color);
					cd.set("powerKick", 20);
					found = true;
				}
				if( found )
					Sfx.playOne([ Mode.SBANK.ballStrong01, Mode.SBANK.ballStrong02 ], rnd(0.4, 0.8));
			}
			if( !Key.isDown(kkick) )
				keyLock.remove(kkick);
		}
		
		
		super.update();
		
		if( cd.has("stun") )
			sprite.alpha = mode.time%2==0 ? 0.5 : 0.7;
		else
			sprite.alpha = 1;
		
		var b = body.getBitmapData().getColorBoundsRect(0xffFFFFFF, 0xff000100, true);
		if( b.width>0 ) {
			head.x = Std.int((b.x - 7) - 1);
			head.y = Std.int((b.y - 14) + 4 );
			if( cd.has("stun") )
				head.scaleX = 1;
			else if( mode.ball.xx < xx-20 && dir==1 )
				head.scaleX = -1;
			else if( mode.ball.xx > xx+20 && dir==-1 )
				head.scaleX = -1;
			else
				head.scaleX = 1;

			torso.x = head.x;
			torso.y = head.y;
		}
		
		// Player ID indicator
		help.x = Std.int(sprite.x - help.width*0.5 + 1);
		help.y = Std.int(sprite.y - 10 - help.height);
		if( Math.abs(dx)>0.1 ) {
			if( help.alpha>0.1 )
				help.alpha-=0.1;
		}
		else {
			if( help.alpha<1 )
				help.alpha+=0.04;
		}
		help.alpha = Math.max(0.1, Math.min(1, help.alpha));
	}
}


