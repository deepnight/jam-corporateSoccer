import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;

typedef Cell = {
	var hard	: Bool;
	var soft	: Bool;
}

@:bitmap("assets/level.png") class GfxLevel extends BitmapData {}
@:bitmap("assets/bg.png") class GfxBg extends BitmapData {}
@:bitmap("assets/space.png") class GfxSpace extends BitmapData {}

class Level {
	public var bg			: Bitmap;
	var mode				: Mode;
	var destroyed			: Bool;
	var map					: Array<Array<Cell>>;
	var source				: BitmapData;
	var walls				: Bitmap;
	var camera				: Bitmap;
	var screenTexture		: Bitmap;
	var space				: Bitmap;
	var cameraFocus			: Null<Entity>;
	var cameraPt			: {x:Float, y:Float};
	var pt0					: flash.geom.Point;
	var cd					: mt.Cooldown;
	var scoreFields			: Array<flash.text.TextField>;
	
	public var ballSpots	: Array<{cx:Int, cy:Int}>;
	public var goals		: Array<{cx:Int, cy:Int, side:Int}>;
	public var teleports	: Array<{cx:Int, cy:Int}>;
	public var bumpers		: Array<{cx:Int, cy:Int}>;
	
	public function new() {
		mode = Mode.ME;
		destroyed = false;
		goals = new Array();
		teleports = new Array();
		bumpers = new Array();
		ballSpots = new Array();
		pt0 = new flash.geom.Point(0,0);
		cameraPt = {x:0, y:0};
		cd = new mt.Cooldown();
		scoreFields = new Array();
		
		//bg = new Sprite();
		//mode.dm.add(bg, Const.DP_BG);
		//bg.graphics.beginFill(0x1B1E27, 1);
		//bg.graphics.drawRect(0,0, Const.LWID*Const.GRID, Const.LHEI*Const.GRID);
		
		space = new Bitmap( new GfxSpace(0,0) );
		mode.dm.add(space, Const.DP_BG);
		
		bg = new Bitmap( new GfxBg(0,0) );
		mode.dm.add(bg, Const.DP_BG);
		
		walls = new Bitmap( new BitmapData(Const.LWID*Const.GRID, Const.LHEI*Const.GRID, true, 0x0) );
		mode.dm.add(walls, Const.DP_BG);
		
		camera = new Bitmap( new BitmapData(9*Const.GRID-2, 4*Const.GRID-2, false, 0x0) );
		mode.dm.add(camera, Const.DP_BG);
		camera.x = Std.int(20.5*Const.GRID)+1;
		camera.y = Std.int(1.5*Const.GRID)+1;
		
		//var sbd = mt.deepnight.Lib.createTexture(mt.deepnight.Buffer.makeScanline(0x0, 2), camera.bitmapData.width, camera.bitmapData.height, true);
		screenTexture = new Bitmap( mode.tiles.getBitmapData("screenTexture") );
		mode.dm.add(screenTexture, Const.DP_BG);
		//screenTexture.blendMode = flash.display.BlendMode.OVERLAY;
		//screenTexture.alpha = 0.2;
		screenTexture.x = camera.x;
		screenTexture.y = camera.y;
			
		// Red score
		var tf = mode.createField("99");
		mode.dm.add(tf, Const.DP_BG);
		scoreFields[0] = tf;
		tf.blendMode = flash.display.BlendMode.OVERLAY;
		tf.filters = [];
		tf.scaleX = tf.scaleY = 3;
		tf.x = 23;
			
		// Red score
		var tf = mode.createField("99");
		mode.dm.add(tf, Const.DP_BG);
		scoreFields[1] = tf;
		tf.blendMode = flash.display.BlendMode.OVERLAY;
		tf.filters = [];
		tf.scaleX = tf.scaleY = 3;
		tf.x = 240;

		source = new GfxLevel(0,0);
		
		map = new Array();
		for(x in 0...Const.LWID) {
			map[x] = new Array();
			for(y in 0...Const.LHEI) {
				var pixel = source.getPixel(x,y);
				
				if( pixel==0xe56cff )
					bumpers.push({cx:x, cy:y});
								
				if( pixel==0x00FF00 )
					ballSpots.push({cx:x, cy:y});
					
				if( pixel==0xFF0000 )
					goals.push({cx:x, cy:y, side:0});
					
				if( pixel==0x0000FF )
					goals.push({cx:x, cy:y, side:1});
					
				if( pixel==0xffe400 )
					teleports.push({cx:x, cy:y});
					
				map[x][y] = {
					hard	: pixel==0xFFFFFF,
					soft	: pixel==0x5c608c,
				}
			}
		}
		
		attach();
		updateScores();
	}
	
	public function destroy() {
		destroyed = true;
		
		walls.bitmapData.dispose();
		walls.parent.removeChild(walls);
		
		camera.bitmapData.dispose();
		camera.parent.removeChild(camera);
		
		screenTexture.bitmapData.dispose();
		screenTexture.parent.removeChild(screenTexture);
		
		source.dispose();
	}
	
	
	public inline function hasHardCollision(cx,cy) {
		if( cx<0 || cx>=Const.LWID || cy<0 || cy>=Const.LHEI )
			return true;
		else
			return map[cx][cy].hard;
	}
	
	public inline function hasSoftCollision(cx,cy) {
		if( cx<0 || cx>=Const.LWID || cy<0 || cy>=Const.LHEI )
			return true;
		else
			return map[cx][cy].soft;
	}
	
	
	public function attach() {
		var wbd = walls.bitmapData;
		
		for(cx in 0...Const.LWID)
			for(cy in 0...Const.LHEI) {
				var x = cx*Const.GRID;
				var y = cy*Const.GRID;
				if( hasHardCollision(cx,cy) )
					mode.tiles.drawIntoBitmap(wbd, x,y, "wall", mode.tiles.getRandomFrame("wall"), 0,0);
				
				if( hasSoftCollision(cx,cy) ) {
					//bg.graphics.beginFill(0x5C6183,1);
					//bg.graphics.drawRect(x, y, Const.GRID, Const.GRID);
				}
			}
			
		wbd.applyFilter(wbd, wbd.rect, pt0, new flash.filters.GlowFilter(0x0,0.4, 4,4,10, 1,true) );
		wbd.applyFilter(wbd, wbd.rect, pt0, new flash.filters.GlowFilter(0x979BBD,1, 2,2,4, 1,true) );
		wbd.applyFilter(wbd, wbd.rect, pt0, new flash.filters.GlowFilter(0x0,0.5, 2,2,4) );
		wbd.applyFilter(wbd, wbd.rect, pt0, new flash.filters.DropShadowFilter(3, -90, 0x0,0.3, 0,0) );
	}
	
	public function getTeleportDestination(cx,cy) {
		for(t in teleports) {
			if( cy==t.cy && cx!=t.cx ) {
				return {cx:t.cx + (t.cx>cx ? -2 : 2), cy:t.cy};
			}
		}
		throw "error, no teleport matching "+[cx,cy];
	}
	
	public function setCameraFocus(e:Entity) {
		if( e!=cameraFocus && !cd.hasSet("cameraSwap", 40) ) {
			cd.set("noise", mt.deepnight.Lib.rnd(2, 4));
			cameraFocus = e;
		}
	}
	
	public function updateScores() {
		var tf = scoreFields[0];
		tf.text = Std.string( mode.scores[0] );
		tf.width = tf.textWidth+5;
		tf.x = Std.int(45 - tf.width*0.5);
		
		var tf = scoreFields[1];
		tf.text = Std.string( mode.scores[1] );
		tf.width = tf.textWidth+5;
		tf.x = Std.int(262 - tf.width*0.5);
	}
	
	public function update() {
		if( destroyed )
			return;
			
		//space.x = Math.cos(1+mode.time*0.001) * space.width*0.3;
			
		cd.update();
		var fx = mode.fx;
		
		for(g in goals)
			fx.goalZone(g.cx, g.cy, g.side);
			
		for(t in teleports)
			fx.teleporter(t.cx, t.cy);
			
		for(b in bumpers)
			fx.bumper(b.cx, b.cy);
			
		var cbd = camera.bitmapData;
		if( cd.has("noise") )
			cbd.noise(Std.random(99999), 100, 160, true);
		else {
			cbd.fillRect(cbd.rect, 0x0);
			var e = cameraFocus==null ? mode.ball : cameraFocus;
			var recal = 0.20;
			cameraPt.x += ((e.xx-cbd.width*0.5) - cameraPt.x ) * recal;
			cameraPt.y += ((e.yy-cbd.height*0.5-8) - cameraPt.y ) * recal;
			cameraPt.x += Math.sin(mode.time*0.07) * 0.3;
			cameraPt.y += Math.cos(mode.time*0.06) * 0.3;
			var r = new flash.geom.Rectangle(cameraPt.x, cameraPt.y, cbd.width, cbd.height);
			cbd.copyPixels(mode.buffer.getBitmap(), r, pt0);
			cbd.applyFilter(cbd, cbd.rect, pt0, mt.deepnight.Color.getColorizeMatrixFilter(0x5A3599, 0.6, 0.4));
			cbd.applyFilter(cbd, cbd.rect, pt0, new flash.filters.BlurFilter(2,0));
		}
	}
}