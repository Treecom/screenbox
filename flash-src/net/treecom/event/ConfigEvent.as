package net.treecom.event {  
    
	import flash.events.Event;
	
     public class ConfigEvent extends Event {
			 
			static public var CONFIG_LOADED:String = "configLoaded";
			static public var CONFIG_IO_ERROR:String = "configIOError";			
			static public var CONFIG_CHANGE:String = "configChange";
 			
            public var scope:*;
			
            public function  ConfigEvent(scr:*, type:String, bubbles:Boolean = false, cancelable:Boolean = false){
            	super(type, bubbles,cancelable);
            	scope = scr;        
        	}
    }
}