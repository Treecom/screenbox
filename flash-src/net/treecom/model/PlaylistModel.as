package net.treecom.model {
 	
	import fl.data.*;
	import fl.events.*;
	import flash.events.*;
	import flash.events.Event;	
	import flash.events.IOErrorEvent;	
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import com.adobe.serialization.json.*;
 
	import net.treecom.AppModel;
	import net.treecom.event.ModelEvent;
 
	public class PlaylistModel extends AppModel {
		   
		public function PlaylistModel(_config:Object) {
			super(_config);
 			if (config.pls && config.plsReload){
				load(config.domain + config.pls, config.plsReload);								  
			}
		}
	}	
}
