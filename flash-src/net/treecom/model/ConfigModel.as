package net.treecom.model {
 
	import net.treecom.AppModel;
	import net.treecom.event.ModelEvent;
	import net.treecom.event.ConfigEvent;
	
	public class ConfigModel extends AppModel {
	 
	 	private var defaultConfig:Object = {
				domain: 'http://localhost',
				confUrl: '/config',
				confInterval: (1000*30),
				pls: '/playlist',
				plsReload: (1000*30),
				media_folder: '/files/media/',
				playlogUrl: '/playlog',
				playlogInterval: (1000*60),
				logerUrl: '/loger',
				width: 1280,
				height: 720,
				x:0,
				y:0,
				ratio:false,
				volume:1,				
 				streamAudio: false, 
				streamAudioUrl: '', 
				streamAudioProxy: true, 
				streamAudioVolume: 1,
 				log: null,
				loger: false,
				logToAlert: false,
				playerBufferTime: 0,
				playerSmoothing: false,
				playerClipTween: false
		}; 
		
		private var eventsReady:Boolean = false;
		
		public function ConfigModel():void {								
			super(defaultConfig);			  
		}  
 		
		public function loadConfig():void {
 			if (config.domain && config.confUrl && config.confInterval){				
 				if (eventsReady==false){
					this.addEventListener(ModelEvent.CHANGE, configChanged, false,0,true);
					this.addEventListener(ModelEvent.LOADED, configLoaded, false,0,true);
					this.addEventListener(ModelEvent.BEFORE_LOAD, configBeforeLoad, false,0,true);
					eventsReady = true;
				}
 				this.load(config.domain +  config.confUrl, config.confInterval);
			}
		}
		
		private function configBeforeLoad(e:ModelEvent):void{
			this.removeAll();
		}
		
		private function configLoaded(e:ModelEvent):void {
			config.log('Config loaded');
 			refreshConfig();
			this.removeEventListener(ModelEvent.LOADED, configLoaded);
			dispatchEvent(new ConfigEvent(this, ConfigEvent.CONFIG_LOADED));
		}
		
		private function configChanged(e:ModelEvent):void {
 			refreshConfig();
		}
		
		private function refreshConfig(){			
			if (this.length>0){
 				var item:Object = this.getItemAt(0);
				var changed:Boolean = false;
 				if (item && item!=null){
					for (var s:String in item){
 						if (item[s]!=config[s] || !config.hasOwnProperty(s)){
							changed = true;
 						}
						set(s, item[s]);
					}
  					
					if (changed){
						dispatchEvent(new ConfigEvent(this, ConfigEvent.CONFIG_CHANGE));
					}
					
					item = null;					 
				}
 			}			
		}
		
		public function set(name:String, val:*):void {
			config[name] = null;
			config[name] = val;
		}
		
		public function get(name:String = null):Object {
			if (name==null){
				return config;
			} else {
				if (config.hasOwnProperty(name)){
					return config[name];
				} else {
					return null;
				}
			}
			
		}
	}	
}
