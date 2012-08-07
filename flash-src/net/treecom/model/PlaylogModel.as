package net.treecom.model {
 	
	import fl.data.*;
	import fl.events.*;
	import flash.events.*;

 	import net.treecom.AppModel;
	import net.treecom.event.ModelEvent;
  
	public class PlaylogModel extends AppModel {
		    		
		public function PlaylogModel(_config:Object) {
			super(_config);
			
			if (config.playlogUrl && config.playlogInterval){
				save(config.domain + config.playlogUrl, config.playlogInterval);
				this.addEventListener(ModelEvent.SAVE, onSaveLog, false,0,true); 
				this.addEventListener(ModelEvent.IOERROR, onSaveLogError, false,0,true); 
			}
		}
		
		 
		private function onSaveLog(e:ModelEvent):void {			
			config.log('Playlog send..');		
			this.removeAll();
		}
		
		private function onSaveLogError(e:IOErrorEvent):void {			
			config.log('Playlog error:' + e.text);
		}
 		 
		public function logItem(item:Object):void {
			if (item.id){
				var dt:Date = new Date();
				item['time'] = dt.getTime();
				this.addItem(item);
			}			
		}
	}	
}
