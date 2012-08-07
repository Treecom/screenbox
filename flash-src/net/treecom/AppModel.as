package net.treecom {
	
	import fl.data.*;
	import fl.events.*;
	import flash.events.*;
	import flash.utils.Timer;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import com.adobe.serialization.json.*;
	
	import net.treecom.event.ModelEvent;
	
	public class AppModel extends DataProvider {
 				
		public var currentIndex:Number = 0;		
	 	public var config:Object;
		public var reload:Number;
		public var resave:Number;
		public var dataUrl:String;
		private var loadTimer:Timer;
		private var saveTimer:Timer;		
		
		public function AppModel(_config:Object){
			super();
			config = _config;			
			this.addEventListener(DataChangeEvent.DATA_CHANGE, modelChanged);
		}
		 		
		public function get item():Object{
			try {
				return getItemAt(currentIndex);
			} catch(e:*){
			}
			return null;
		}
		
		public function next():Object {
			if (currentIndex<this.length-1){
				currentIndex++;
			} else {
				currentIndex = 0;
			}
			 
			return item; 
		}
		
		public function previous():Object {
			if (currentIndex<this.length-1 && currentIndex>0){
				currentIndex--;
			} else {
				currentIndex = this.length-1;
			}
			 
			return item;
		}
		
		public function load(url:String = '', _timer:Number=0):void {
			
			dispatchEvent(new ModelEvent(this, ModelEvent.BEFORE_LOAD));
			
  			if (_timer>0){
				reload = _timer;
			}
			
			if (reload>0 && loadTimer==null){
				loadTimer = new Timer(reload);
				loadTimer.addEventListener(TimerEvent.TIMER, timerLoadEvent, false,0,true);
				loadTimer.start();
			}
			
			if (url && url!=''){
				dataUrl = url;
			}
			
			if (dataUrl && dataUrl!='' && dataUrl!=null){
				var tm:Date = new Date();
				
				var modelLoader:URLLoader = new URLLoader();				
				modelLoader.addEventListener(Event.COMPLETE, onModelLoaded, false,0,true);
				modelLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoadingError, false,0,true); 
				modelLoader.load(new URLRequest(dataUrl + '?t=' + tm.milliseconds.toString()));				
			}
   		}
		
		private function onModelLoaded(e:Event):void {
			var _items = parseJSON(e.target.data);
			if (_items.length>0){
					if (this.length>0){
						if (this.length!=_items.length){							
							currentIndex = 0;
							removeAll();
							dispatchEvent(new ModelEvent(this, ModelEvent.INDEX_CHANGE));							
							addItems(_items);							
						}						
					} else {  
						addItems(_items);
					}
 					dispatchEvent(new ModelEvent(this, ModelEvent.LOADED));
			}			
			_items = null;
			try {
				e.target.removeEventListener(Event.COMPLETE, onModelLoaded);
				e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoadingError); 
 			} catch (e:Error){}
		}
		
		private function onLoadingError(e:IOErrorEvent):void {
			try {
				e.target.removeEventListener(Event.COMPLETE, onModelLoaded);
				e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoadingError); 
 			} catch (e:Error){}			
			dispatchEvent(new ModelEvent(this, ModelEvent.IOERROR));
		}
		
		private function modelChanged(e:DataChangeEvent):void { 			
			dispatchEvent(new ModelEvent(this, ModelEvent.CHANGE));
		}
		
		private function timerLoadEvent(e:TimerEvent):void {			
			load();
		}
		
		public function parseJSON(content:String):Array{
			var _items:Array = new Array();
			try {
				_items = JSON.decode(content) as Array;				
 			} catch (e:*) { 	
 				dispatchEvent(new ModelEvent(this, ModelEvent.PARSE_ERROR));
			}
			return _items;
		}
		
		public function save(url:String = '', _time:Number = 0):void {	
		
			dispatchEvent(new ModelEvent(this, ModelEvent.BEFORE_SAVE));
 		
			if (_time>0){
				resave = _time;
			}
			
			if (resave>0 && saveTimer==null){
				saveTimer = new Timer(resave);
				saveTimer.addEventListener(TimerEvent.TIMER, timerSaveEvent, false,0,true);
				saveTimer.start();
			}
			
			if (url!=''){
				dataUrl = url;
			}
 			
			var _data:Array = this.toArray() as Array;
			
			if (_data.length>0){				
			
				var tm:Date = new Date();				
				var req:URLRequest = new URLRequest();
				var vars:URLVariables = new URLVariables();  
				
				vars.savedata = JSON.encode({items:_data});
				req.data = vars;
				req.url = dataUrl + '?t=' + tm.time.toString();
				req.method = 'POST';
 				
				var modelSaver:URLLoader = new URLLoader();				
				modelSaver.addEventListener(Event.COMPLETE, onModelSave, false,0,true);
				modelSaver.addEventListener(IOErrorEvent.IO_ERROR, onModelSaveError, false,0,true);
				modelSaver.load(req);
			}
			
			_data = null;
		}
		
		// @todo: add server status check after save 
		private function onModelSave(e:Event):void {
			try {
				e.target.removeEventListener(Event.COMPLETE, onModelSave);
				e.target.removeEventListener(IOErrorEvent.IO_ERROR, onModelSaveError); 
 			} catch (e:Error){
				trace('onModelSave Error');
			}
 			dispatchEvent(new ModelEvent(this, ModelEvent.SAVE));
 		}
		 
		private function onModelSaveError(e:Event):void {		
			trace('onModelSaveError');
			trace(e);
			try {
				e.target.removeEventListener(Event.COMPLETE, onModelSave);
				e.target.removeEventListener(IOErrorEvent.IO_ERROR, onModelSaveError); 
 			} catch (e:Error){
				trace('onModelSaveError Error');
			}
 			dispatchEvent(new ModelEvent(this, ModelEvent.IOERROR));
 		}
		
		private function timerSaveEvent(e:TimerEvent):void {			
			save();
		}
	}	
}
