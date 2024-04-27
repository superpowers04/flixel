package flixel.util;

#if sys
import sys.io.File;
import sys.FileSystem;
#end 
#if lime
import lime.utils.Assets;
#else
import openfl.utils.Assets;
#end 

import haxe.io.Path;
import haxe.io.Bytes;
import openfl.utils.ByteArray;

typedef Handle = #if sys File #else Assets #end;

enum Directory { 
	DATA;
	SOUNDS;
	IMAGES;
    FONTS;
    MUSIC;
	CUSTOM;
}
/**
 * A Files Util class which is used for getting preloaded or local files.
 * It stores files and filePaths and can even be used with default flixel directories or custom ones.
 */
class FlxFileUtil {

    public static var files:Array<String> = [];
    public static var filePath:String = '';
    public static var directory(default, set):Dynamic;

    /**
	 * Checks if the file path provided exists in preloaded or local directories.
	 *
	 * @param   Url      The filepath String.
	 * @return  Bool     True/False.
	 */
    public static inline function check(Url:String) {
        if(#if sys FileSystem.exists(Url) #end || Assets.exists(Url)) {
            return true;
        }
        return false;
    }

    /**
	 * Gets bytes within the filepath provided if they exist in preloaded or local directories.
     * Returns a new Bytes instance of 0 if the directory is null.
	 *
	 * @param   Url      The filepath String.
	 * @return  Bytes    The haxe.io Bytes.
	 */
    public static function getBytes(Url:String) {
        if (check(Url)) {
            return Handle.getBytes(Url);
        }
        return Bytes.alloc(0);
    }
    /**
	 * Gets `String` content from a filepath provided if it exists in preloaded or local directories.
	 *
	 * @param   Url      The filepath String.
	 * @return  String   The content.
	 */
    public static function getContent(url:String):String {
        if(check(url)) {
            return Handle.getContent(url);
        }
        return '';
    }
    /**
	 * Gives a Integer of the amount of items in a directory.
     * If this platform is a non sys target a list will be provided of all preloaded Binary objects.
	 *
	 * @param   Url      The filepath String.
	 * @return  Int      Items in Directory
	 */
    public static inline function count(dir:String) {
        #if sys return sys.FileSystem.readDirectory(dir).length; #else Assets.list(BINARY).length; #end
	}

    /**
	 * Indexes a directory for non caseSensitive files key words will be found in the sys directory.
     * If this platform is a non sys target this function will return nothing.
	 *
	 * @param   Dir         The filepath String.
     * @param   Indexes     The Key words to find.
     * @param   Exclusions  Any key words and or files to ignore.
	 * @return  FilePath    The Directory for this File.
	 */
    #if sys
    public static function indexDir(dir:String, index:String, ?exclusion:String='') {
		try {
			files = sys.FileSystem.readDirectory(dir);
			final fileName = Path.withoutDirectory(Path.normalize(index)).toLowerCase();
			for (file in files) { // non case sensitive directory finding name a thing wrong and if it atleast contains the key words load the path!
				final fileLowerCase:String = file.toLowerCase();
				if (exclusion != '' && fileLowerCase.indexOf(exclusion.toLowerCase()) != -1) {
					continue; // skip files that contain the exclusion string
				}
				if (fileLowerCase.indexOf(fileName.toLowerCase()) != -1) {
					filePath = dir+'/'+file;
				}
			}	
			files = [];
		} catch (e:Dynamic) {
			FlxG.log.warn('Directory $dir : does not exist or the file permissions are missing!!');
		}
		return filePath;
	}
    #end
    /**
	 * Sets the working directory of the `FlxFileUtil` and returns the path with prefixes.
     * and returns Files located inside of this directory.
     * If this platform is a non sys target this function will return nothing.
     * 
     * A CUSTOM directory item can be specified allowing the exact directory to be read.
	 *
	 * @param   Dir         An array of the Directory
	 * @return  Files       An Array of the files inside this directory.
	 */
    #if sys
    public static function set_directory(dir:Array<Dynamic>) {
		var folder:String;
		switch(dir[0]) {
			case DATA:
				folder = './assets/data/' + dir[1];
			case MUSIC:
				folder = './assets/music/' + dir[1];
			case IMAGES:
				folder = '/assets/images/' + dir[1];
            case FONTS:
                folder = '/assets/fonts/' + dir[1];
            case SOUNDS:
                folder = '/assets/images/' + dir[1];
			case CUSTOM:
				folder = dir[1];
		}
		return directory = sys.FileSystem.readDirectory(folder);
	}
    #end
}