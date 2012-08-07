package net.treecom {
 
 	import flash.display.*;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import net.treecom.controller.*;
	import net.treecom.view.*;
	import net.treecom.model.*;
		
	public class AppController extends EventDispatcher {
		
		public var config:Object;
		public var view:MediaBoxView;
		
		public function AppController(_view:MediaBoxView, _config:Object = null):void {
			super();
 			config = _config;
			view = _view;					
		}		

	}	
}			