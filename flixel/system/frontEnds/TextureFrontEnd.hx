package flixel.system.frontEnds;

import openfl.display.BitmapData;
import openfl.display3D.textures.*;
import openfl.events.Event;
import openfl.Assets;
import flixel.FlxG;
import openfl.Lib;
import flixel.graphics.FlxTexture;
import lime.graphics.opengl.GL;
/**
 * Internal storage system to prevent `FlxTextures` from being used repeatedly in video memory.
 * 
 * Accessed via `FlxG.texture`.
 */
class TextureFrontEnd {
    var _cache:Map<String, FlxTexture> = [];
	var _maxWidth:Float;
	var _maxHeight:Float;
	var _prevWidth:Float;
	var _prevHeight:Float;
	
	public var memory(get, never):Float;
	public var _estVram:Float = 0;

	final DISPLAY_ALLOCATION:Float = 0.1; // With full window AA the display uses 25 mb of vram on window init.
	final BITS_PER_PIXEL:Int = 4;
	final DISPLAY_DENSITY:Float = Lib.current.stage.window.display.dpi;

	public function new()
	{
		_maxWidth = FlxG.initialWidth;
		_maxHeight = FlxG.initialHeight;
		
		if(FlxG.stage.context3D != null) {
			Lib.current.stage.addEventListener(Event.RESIZE, _resize);
		}
	}
	
	public function add(bitmap:FlxTexture, key:String, ?internal:Bool) {
		
		if(findKeyForTexture(bitmap) == null) {
			if(!internal) {
				_estVram += ((bitmap.width * bitmap.height) * BITS_PER_PIXEL)*2;
			} else {
				_estVram += ((bitmap.image.width * bitmap.image.width) * bitmap.image.buffer.bitsPerPixel)/8;
			}
			//trace('texture added : ' + key);
		}
		_cache.set(key, bitmap);
	}

	 /**
	 * Gets key from texture cache for specified BitmapData
	 *
	 * @param	tex	FlxTexture to find in cache
	 * @return	Textures key or null if there isn't such FlxTexture in cache
	 */
	public function findKeyForTexture(tex:FlxTexture):String
	{
		for (key in _cache.keys())
		{
			var obj = _cache.get(key);
			@:privateAccess
			if (obj != null && obj.__texture == tex.__texture) {
				return key;
			}
		}
		return null;
	}

    /**
	 * Gets Texture object from this storage by specified key.
	 * @param	key	Key for Texture object (its name)
	 * @return	Texture with the key name, or null if there is no such object
	 */
	public inline function get(key:String):FlxTexture
	{
		return _cache.get(key);
	}

    /**
	 * Totally removes specified Texture object.
	 * @param	Texture object you want to remove and destroy.
	 */
	public function remove(tex:String):Void
	{
		if (tex != null)
		{
			removeKey(tex);
			//_totalmem -= ((graphic.bitmap.width * graphic.bitmap.height)*graphic.bitmap.bitsPerPixel)/BITS_PER_PIXEL;
		}
	}

    /**
	 * Totally removes Texture objects with specified key.
	 * @param	key	the key for cached Texture object.
	 */
	public function removeByKey(key:String):Void
	{
		if (key != null)
		{
			var obj = get(key);
			removeKey(key);

			if (obj != null)
				obj.dispose();
                obj = null;
		}
	}

	inline function removeKey(key:String, ?dispose:Bool = true):Void
	{
		if (key != null)
		{	
			if(dispose) {
				_cache.get(key).dispose();
			}
			Assets.cache.removeBitmapData(key);
			_cache.remove(key);
		}
	}

	public function clear() {
		for(key in _cache.keys()) {
			var obj = get(key);
			if (obj != null) {
				//removeKey(key, false);
				@:privateAccess {
					if(obj.__texture != null) {
						obj.__texture.dispose();
					}
				}
				obj.dispose();
				obj = null;
			}
		}
		_cache.clear();
		_estVram = 0;
		getDisplayVram();
	}

	public function get_memory():Float {
		return _estVram / Math.floor(1024 * 1024 * 1024) + DISPLAY_ALLOCATION;
	}

	private function _resize(E:Event) {
		getDisplayVram();
	}

	// I gen need to make this better its so awful.
	private function getDisplayVram() {
		_prevWidth = _maxWidth;
		_prevHeight = _maxHeight;

		_maxWidth = Lib.current.stage.window.width;
		_maxHeight = Lib.current.stage.window.height;

		final allocationW:Float = (_maxWidth - _prevWidth);
		final allocationH:Float = (_maxHeight - _prevHeight);

		if(allocationW < 0 || allocationH < 0 || _estVram < 1) {
			_estVram -= (((allocationW * allocationH)*DISPLAY_DENSITY)/8);
		} else {
			_estVram += (((allocationW * allocationH)*DISPLAY_DENSITY)/8);
		}

		_prevWidth = _maxWidth;
		_prevHeight = _maxHeight;
	}
}

