package en;

import mt.flash.Sfx;

class Ball extends Entity {
	public function new() {
		super();
		setPos(20,20);
		radius = 3;
		bumperPower *= 0.8;
		repel = false;
		gravity *= 0.7;
		color = 0xFFFFFF;
		frictX = frictY = 0.93;
		kickable = true;
		
		sprite.setGroup("ball");
		sprite.setCenter(0.5, 1);
		mode.dm.add(sprite, Const.DP_BALL);
		
		disable();
	}
	
	public function disable() {
		kickable = false;
		outOfGame = true;
	}
	public function enable() {
		kickable = true;
		outOfGame = false;
	}
	
	override function onHitWall() {
		dx = -dx*0.8;
	}
	
	override function onLand() {
		if( Math.abs(dy)>=0.1 )
			Sfx.playOne([ Mode.SBANK.ballLight01, Mode.SBANK.ballLight02, Mode.SBANK.ballLight03 ], rnd(0.1, 0.2));
		dy = -dy*0.9;
		stable = false;
	}
	
	override function onKick(e:Entity) {
		super.onKick(e);
		mode.level.setCameraFocus(e);
	}

	public function respawn() {
		#if debug
		setPos(20,30);
		#else
		var pt = mode.level.ballSpots[ Std.random(mode.level.ballSpots.length) ];
		setPos(pt.cx, pt.cy);
		#end
		dx = dy = 0;
		stable = true;
		enable();
		fx.ballRespawn(xx,yy-radius);
	}
	
	override function update() {
		if( !outOfGame )
			for(g in mode.level.goals) {
				if( cx==g.cx && cy==g.cy ) {
					mode.goal(g.side==0 ? 1 : 0);
					fx.goal(xx,yy, 0xffffff);
					return;
				}
			}
		super.update();
	}
}
