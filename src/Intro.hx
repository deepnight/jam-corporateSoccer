import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.BlendMode;
import mt.deepnight.Buffer;

@:bitmap("assets/title.png") class GfxTitle extends BitmapData {}

class Intro extends mt.deepnight.Mode {
	var bg					: Bitmap;
	public var buffer		: Buffer;
	
	public function new() {
		super();
		
		flash.Lib.current.addChild(root);
		
		buffer = new Buffer(320,200, Const.UPSCALE, false, 0x0);
		root.addChild(buffer.render);
		buffer.setTexture( Buffer.makeMosaic(Const.UPSCALE), 0.1, true );

		root.graphics.beginFill(0x0,1);
		root.graphics.drawRect(0,0, Const.WID, Const.HEI);
		
		bg = new Bitmap( new GfxTitle(0,0) );
		buffer.addChild(bg);
		bg.visible = false;
		
		delayer.add( function() {
			bg.visible = true;
			var s = new Sprite();
			buffer.addChild(s);
			Mode.SBANK.intro02().play();
			s.graphics.beginFill(0xFFFF00, 0.8);
			s.graphics.drawRect(0,0, buffer.width, buffer.height);
			s.blendMode = BlendMode.ADD;
			tw.create(s, "alpha", 0, 1500).onEnd = function() {
				s.parent.removeChild(s);
			}
		}, 600);
		
		root.stage.addEventListener( flash.events.KeyboardEvent.KEY_DOWN, start);
		root.stage.addEventListener( flash.events.MouseEvent.CLICK, start );
	}
	
	public function start(_) {
		if( cd.hasSet("start", 99999) )
			return;
			
		//root.stage.removeEventListener( flash.events.KeyboardEvent.KEY_DOWN, start );
		Mode.SBANK.intro01(1);
		tw.create(bg, "alpha", 0, 1500).onEnd = function() {
			destroy();
			new Mode();
		}
	}
	
	override function destroy() {
		super.destroy();
		bg.bitmapData.dispose();
		buffer.destroy();
	}
	
	override function update() {
		super.update();
		
		buffer.update();
	}
}