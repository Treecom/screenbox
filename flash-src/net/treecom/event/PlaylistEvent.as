package net.treecom.event {  
    
	import flash.events.Event;
	
     public class ModelEvent extends Event {
			
			static public var READY:String = "ready";
			static public var LOADED:String = "loaded";
			static public var IO_ERROR:String = "ioError";
			static public var CHANGE:String = "change";
			static public var SAVE:String = "save";
						
            public var scope:*;
			
            public function  ModelEvent(scr:*, type:String, bubbles:Boolean = false, cancelable:Boolean = false){
            	super(type, bubbles,cancelable);
            	scope = scr;        
        	}
    }
}