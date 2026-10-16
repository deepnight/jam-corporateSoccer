import mt.deepnight.Buffer;
import mt.flash.Sfx;
import mt.deepnight.SpriteLibBitmap;
import mt.flash.DepthManager;

@:bitmap("assets/tiles.png") class GfxTiles extends flash.display.BitmapData {}

class Mode extends mt.deepnight.Mode { //}
	public static var ME : Mode;
	public static var SBANK = Sfx.importDirectory("sfx");
	
	public var buffer		: Buffer;
	public var fx			: Fx;
	public var tiles		: SpriteLibBitmap;
	public var level		: Level;
	public var dm			: DepthManager;
	public var ball			: en.Ball;
	
	public var scores		: Array<Int>;
	public var suspended	: Bool;
	public var isOver		: Bool;
	public var chrono		: Float;
	var chronoField			: flash.text.TextField;
	var music				: Sfx;

	public function new() {
		super();
		
		mt.flash.Key.init();
		flash.Lib.current.addChild(root);
		ME = this;
		flash.Lib.current.stage.quality = flash.display.StageQuality.LOW;
		
		scores = [0,0];
		isOver = false;
		suspended = false;
		chrono = 30 * 60*3;
		//chrono = 30 * 1;
		
		Sfx.setGlobalVolume(Const.VOLUME);
		Sfx.setChannelVolume(1, Const.MUSIC_VOLUME);
		music = SBANK.music();
		music.playLoopOnChannel(1);
		
		tiles = new SpriteLibBitmap( new GfxTiles(0,0) );
		tiles.setSliceGrid(14,14);
		tiles.sliceGrid("idle", 0,0);
		tiles.sliceGrid("jump", 1,0);
		tiles.sliceGrid("jetpack", 2,0);
		tiles.sliceGrid("stun", 0,2);
		tiles.sliceGrid("run", 0,1, 8);
		tiles.defineAnim("0-7(2)");
		tiles.sliceGrid("torso", 0,3, 2);
		tiles.sliceGrid("head", 0,4, 4);
		tiles.sliceGrid("headStun", 0,5, 4);
		tiles.sliceGrid("ball", 0,10);
		
		tiles.slice("screenTexture", 0,87, 52,22);
		tiles.setSliceGrid(Const.GRID, Const.GRID);
		tiles.sliceGrid("wall", 0,20, 3);
		//tiles.sliceGrid("blue_idle", 0,0, 2);
		//tiles.defineAnim(0-1(5));
		
		buffer = new Buffer(320,200, Const.UPSCALE, false, 0x0);
		root.addChild(buffer.render);
		buffer.setTexture( Buffer.makeMosaic(Const.UPSCALE), 0.1, true );
		dm = buffer.dm;
		
		level = new Level();
		fx = new Fx();
		
		new en.Player(0);
		new en.Player(1);
		new en.Player(2);
		new en.Player(3);
		ball = new en.Ball();
		
		#if debug
		en.Player.ALL.get(1).setPos(23,30);
		#end
		
		engage(500);
		
		chronoField = createField("0:00", 0x7E5ED5);
		dm.add(chronoField, Const.DP_BG);
		chronoField.filters = [];
		chronoField.visible = false;
		chronoField.scaleX = chronoField.scaleY = 2;
		chronoField.blendMode = flash.display.BlendMode.ADD;
	}
	
	public function gameOver() {
		chrono = 0;
		isOver = true;
		music.setVolume(0.1);
		Mode.SBANK.intro01().play();
		if( scores[0]>scores[1] ) {
			fx.flashBang(0xFF0000, 0.8, 4000);
			fx.announce("Red wins!", 0xFF7575, 5000);
		}
		else if( scores[1]>scores[0] ) {
			fx.flashBang(0x0080FF, 0.8, 4000);
			fx.announce("Blue wins!", 0x0080FF, 5000);
		}
		else {
			fx.flashBang(0xFFFFFF, 0.5, 4000);
			fx.announce("Draw!!", 0xFFFFFF, 5000);
		}
		ball.disable();
		delayer.add(function() {
			destroy();
			new Intro();
		}, 6000);
	}
	
	public function engage(pause:Float) {
		suspended = true;
		ball.disable();
		music.setVolume(0.2);
		delayer.add(function() {
			SBANK.robotReady(0.6);
			fx.announce("Ready?", 0xFF8000);
			delayer.add( function() {
				suspended = false;
				ball.respawn();
				fx.announce("GO!");
				fx.flashBang(0xFFFF00, 0.7, 500);
				SBANK.robotGo(1);
				SBANK.robotGo(1);
				SBANK.engage01(1);
				music.setVolume(1);
			}, 2000);
		}, pause);
	}
	
	public function goal(side:Int) {
		if( side==0 )
			SBANK.goal02().play();
		else
			SBANK.goal03().play();
		scores[side]++;
		level.updateScores();
		fx.flashBang(side==0 ? 0xFF0000 : 0x0080FF, 0.7, 3000);
		if( side==0 )
			fx.announce("Red\nscored!", 0xFFCCCC, true);
		else
			fx.announce("Blue\nscored!", 0xA4D6FF, false);
		engage(2500);
	}
	
	override function destroy() {
		super.destroy();
		level.destroy();
		fx.destroy();
		music.stop();
		for(e in Entity.ALL)
			e.destroy();
		buffer.destroy();
	}
	
	public function createField(str:Dynamic, ?col=0xFFFFFF, ?adjustSize=true) {
		var f = new flash.text.TextFormat();
		f.font = "def";
		f.size = 16;
		f.color = col;
		
		var tf = new flash.text.TextField();
		tf.width = adjustSize ? 500 : 300;
		tf.height = 50;
		tf.mouseEnabled = tf.selectable = false;
		tf.defaultTextFormat = f;
		tf.embedFonts = true;
		tf.htmlText = Std.string(str);
		tf.multiline = tf.wordWrap = true;
		if( adjustSize ) {
			tf.width = tf.textWidth+5;
			tf.height = tf.textHeight+5;
		}
		
		tf.filters = [
			new flash.filters.GlowFilter(0x0,1, 2,2,5),
		];
		
		return tf;
	}
	
	override function update() {
		super.update();
		
		if( mt.flash.Key.isToggled(flash.ui.Keyboard.M) )
			music.toggleMute();
			
		if( mt.flash.Key.isToggled(flash.ui.Keyboard.ESCAPE) )
			gameOver();
		
		BSprite.updateAll();
		
		for(e in Entity.ALL)
			e.update();
		for(e in Entity.TOKILL)
			e.unregister();
		Entity.TOKILL = [];
		
		if( !suspended && chrono>0 )
			chrono--;
		
		if( chrono%30==0 ) {
			var c = DateTools.parse( 1000 * chrono/30 );
			chronoField.text = c.minutes+":"+mt.deepnight.Lib.leadingZeros(c.seconds, 2);
			chronoField.x = Std.int(148	 - chronoField.textWidth*chronoField.scaleX*0.5);
			chronoField.y = 2;
			chronoField.visible = true;
		}
		
		if( chrono<=0 && !isOver )
			gameOver();
		
		level.update();
		fx.update();
		buffer.update();
	}
}
