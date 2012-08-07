package net.treecom {
	
	import flash.display.*;
	import flash.events.*	
	import flash.system.Security;
	import fl.video.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;	
	
	import net.treecom.AppModel;	
	import net.treecom.AppView;
	import net.treecom.AppController;
		
	import net.treecom.controller.PlayerController;
	import net.treecom.controller.AudioPlayerController;
	import net.treecom.view.MediaBoxView;
	import net.treecom.model.ConfigModel;
	import net.treecom.event.PlayerEvent;
	import net.treecom.event.ModelEvent;
	import net.treecom.event.ConfigEvent;
	
	public class App extends MovieClip {
 		
		public var player:PlayerController;
		public var audioPlayer:AudioPlayerController;		
		public var view:MediaBoxView;
		public var config:ConfigModel;
		
		public function App():void {
			Security.allowDomain('*');
			
 			config = new ConfigModel();
 			config.addEventListener(ConfigEvent.CONFIG_CHANGE, configChange);
 			config.set('log', this.log);
			config.loadConfig();
 		}
		
 		private function configChange(e:ConfigEvent): void {			
			this.log('App.configChange');			
			if (player){
 				switchAudio(config.get('streamAudio'));
			} else {
				init();
			}
		}
		
		private function init():void{ 			
			
			try { 				
				view   = new MediaBoxView(this, config.config);
				view.fullScreen();
				
				player = new PlayerController(view, config.config);
				player.addEventListener(PlayerEvent.PLAY, playerHandler, false,0,true);
				
				stage.addEventListener(KeyboardEvent.KEY_DOWN, player.keyEvent, false,0,true);
				stage.addEventListener(MouseEvent.CLICK, player.clickEvent, false,0,true);								
								
				view.renderView(); 
 				
				trace('STAGE SIZE: ' + stage.stageWidth + 'x' + stage.stageHeight);				
				trace('STAGE SIZE FS: ' + stage.fullScreenWidth + 'x' + stage.fullScreenHeight);
				
			} catch(e:*){
 				this.log('Error:' + e.message, 'Error initializing !!!');
			}
		}
		
		private function playerHandler(e:PlayerEvent): void {			
 			switchAudio(config.get('streamAudio'));
 			player.removeEventListener(PlayerEvent.PLAY, playerHandler);
		}
		
		public function switchAudio(_on:Boolean = true):void {
			
			this.log('Switch AudioPlayer: ' + (_on ? 'ON':'OFF'));
			
 			if (_on){
				
				// create
 				if (audioPlayer==null && config.get('streamAudio')!=false){
					
					this.log('Switch AudioPlayer: create ');
					
					audioPlayer = new AudioPlayerController(view, config.get());					
				}
				
				// stream
				if (audioPlayer && config.get('streamAudio')!=false){
					
					if (player!=null){
 						player.setVolume(0);
					}
					var url:String = String(config.get('streamAudioUrl'));
					
					this.log('Switch AudioPlayer url:' + url);
					this.log('Switch AudioPlayer streamURL:' + audioPlayer.streamURL);
					
					if (url!=audioPlayer.streamURL){
						
						this.log('Switch AudioPlayer: stream ');
						
 						audioPlayer.stream(url);
					}
 				}
			} else {
				if (audioPlayer!=null){
					audioPlayer.stop();
					audioPlayer = null;
				}
				if (player!=null){
 					player.setVolume(Number(config.get('volume')));
				}
			}
 		}
		
		public function log(str:String, str1:String = null, str2:String = null):void {			
		
			str1 = str1==null ? '' : ' ' + str1;
			str2 = str2==null ? '' : ' ' + str2;
			
			trace(str, str1, str2);
			
			if (config.get('logToAlert')!=false && view){
				view.showAlert(str + str1 + str2, 'Player info', true);			
			}
			
			if (config.get('loger')!=false){
				var loger:URLLoader = new URLLoader();
				loger.addEventListener(IOErrorEvent.IO_ERROR, logerError, false,0,true);
				loger.load(new URLRequest(config.get('domain') + config.get('logerUrl') + '?msg=' + escape(str)));			
			}
		}
		private function logerError(e:IOErrorEvent){
			trace(e.text);
		}
	}	
}

