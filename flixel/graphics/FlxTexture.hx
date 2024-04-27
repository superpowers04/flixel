package flixel.graphics;

#if lime

import openfl.display3D.textures.*;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import lime.graphics.Image;
import flixel.FlxG;

enum Surface {
    CAIRO; // software rendering.
    INTERNAL; // Internal hw texture.
    CONTEXT_3D; // stage3D utilizing the context.
}
/**
 * `FlxTexture`s are designed for rendering bigger `FlxGraphic`s without the overhead of rendering costs and memory.
 *  The texture is created with use of Context3D which is unsupported on Blitting targets.
 *  Textures are internally managed with `TextureFrontEnd` and will clear on a state swap.
 *
 *  On Hardware Targets with debug the `TextureFrontEnd` can report its memory which is a collection of display allocations + textures loaded.
 */
class FlxTexture extends BitmapData {

    public static var _key:Int;
    public static var clearNextBitmaps:Bool = true; 
    @:isVar public var refCount(get, set):Int;

    var _mem:Float;
    var _useCount:Bool;

    override public function new(?bitmap:BitmapData, stage:Surface) {
       
        super(bitmap.image.width, bitmap.height, true, 0x00000000);
        this.image = bitmap.image;
        //}

        image.buffer.bitsPerPixel = 16;
        image.format = BGRA32;
        image.premultiplied = true;
        readable = true;

        createSurface(this, stage);

        if(FlxG.stage.context3D == null) {
           FlxG.log.warn('The Current Context : ' + FlxG.stage.window.context.type + ' : Does Not Support Textures!');
        }
        _clear();
    }

    public function replaceFromBitmapData(Source:BitmapData, ?surface:Surface = CONTEXT_3D) {
        if(FlxG.stage.context3D != null) {
            @:privateAccess
            this.__fromImage(Source.image);
            createSurface(Source, surface);
            Source = null;
        } else {
            FlxG.log.warn('Texture Could Not Be Created! The Current Context : ' + FlxG.stage.window.context.type + ' : Does Not Support It!');
        }
    }

    public function toGraphic(Source:BitmapData) {
        return FlxGraphic.fromBitmapData(this);
    }

    public function fromGraphic(Graphic:FlxGraphic, ?surface:Surface = CONTEXT_3D) {
        createSurface(Graphic.bitmap, surface);
    }

    private function createSurface(bitmap:BitmapData, __surface:Surface) {
        switch(__surface) {
            case CAIRO:
                _textureSurface(bitmap.image);
            case INTERNAL:
                _textureHardware(bitmap.image);
            case CONTEXT_3D:
                _texture(bitmap.image);
        }
        @:privateAccess {
            if(this.__texture != null) {
                FlxG.texture.add(this, '$_key');
            } else if(__surface == INTERNAL) {
                FlxG.texture.add(this, ('$_key'), true);
            }
        }
        _key++;
        _clear();
    }

    /**
	* Creates a context3D Texture that is displayed on the Software renderer.
	*
	* @param   Image      The lime backing image.
	*/
    inline function _textureSurface(image:Image) {
        lock();
        if(FlxG.stage.context3D != null) {
            getTexture(FlxG.stage.context3D);
        }
        getSurface();

        readable = true;
		this.image = FlxG.stage.context3D != null ? null : image;
        unlock();
    }

    /**
	* Creates a context3D Texture that is displayed on the Hardware renderer.
	*
	* @param   Image      The lime backing image.
	*/
    private function _texture(image:Image) {
        lock();
        if(FlxG.stage.context3D != null) {
            __texture = FlxG.stage.context3D.createRectangleTexture(image.width, image.height, BGRA, true);
            @:privateAccess {
                __texture.__uploadFromImage(image);
		        __textureContext = __texture.__textureContext;
            }
        }
        readable = false;
        this.image = FlxG.stage.context3D != null ? null : image;
        unlock();
    }

    /**
	* Internally creates a texture that is used on the lime backing Hardware Buffer. 
    * The bitmapdata will be stored until a GC Clear.
    *
    * on hw targets an opengl texture will be created.
	*
	* @param   Image      The lime backing image.
	*/
    private function _textureHardware(image:Image) {
        __fromImage(image);
        readable = false;
    }
    
    @:noCompletion
    private function _clear() {
        if(clearNextBitmaps) {
            clearMemAsync();
            clearNextBitmaps = false;
        }
    }

    public function get_refCount() {
        return refCount;
    }

    public function set_refCount(val:Int) {
        if(val > 0 && !_useCount) {
            FlxG.texture._estVram += _mem;
            _useCount = true;
        }
        return val;
    }

    function clearMemAsync():Void {
	    var promise = new lime.app.Promise<String>();
	    var progress = 0, total = 10;
	    var timer = new haxe.Timer (25);
	    timer.run = function () {

		    promise.progress (progress, total);
		    progress++;

		    if (progress == total) {
                openfl.system.System.gc();
			    promise.complete("Done!");
			    timer.stop();
            }
	    };
	    return;
    }
}
#end