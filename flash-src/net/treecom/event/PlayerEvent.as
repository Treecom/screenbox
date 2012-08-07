package net.treecom.event {  
    
	import flash.events.Event;
	
     public class PlayerEvent extends Event {
			
			static public var READY:String = "ready";
			static public var LOADED:String = "loaded";
			static public var PLAY:String = "play";
			static public var PLAYLIST:String = "playlist";
			static public var IO_ERROR:String = "ioError";
			
            public var scope:*;
			
            public function  PlayerEvent(scr:*, type:String, bubbles:Boolean = false, cancelable:Boolean = false){
            	super(type, bubbles,cancelable);
            	scope = scr;        
        	}
    }
}