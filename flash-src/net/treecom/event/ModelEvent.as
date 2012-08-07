package net.treecom.event {  
    
	import flash.events.Event;
	
     public class ModelEvent extends Event {
			 
			static public var BEFORE_LOAD:String = "beforeLoad";
			static public var LOADED:String = "loaded";
			static public var IOERROR:String = "modelIOError";
			static public var PARSE_ERROR:String = "parseError";
			static public var CHANGE:String = "change";
			static public var BEFORE_SAVE:String = "beforeSave";
			static public var SAVE:String = "save";
 			static public var INDEX_CHANGE:String = "index";
						
            public var scope:*;
			
            public function  ModelEvent(scr:*, type:String, bubbles:Boolean = false, cancelable:Boolean = false){
            	super(type, bubbles,cancelable);
            	scope = scr;        
        	}
    }
}