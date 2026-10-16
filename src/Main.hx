class Main { //}
	
	static function main() {
		try { haxe.Log.setColor(0xFFFF00); } catch(e:Dynamic) {}
		
		new Intro();
		
		flash.Lib.current.addEventListener( flash.events.Event.ENTER_FRAME, update );
	}
	
	public static function update(_) {
		mt.deepnight.Mode.updateAll(true);
		mt.flash.Sfx.update();
	}
	
}
