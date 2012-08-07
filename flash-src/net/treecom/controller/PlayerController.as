package net.treecom.controller {
	
	import flash.system.System;
	import flash.events.*;
	import flash.display.*;
	import flash.media.*;
	import flash.utils.*;
	import flash.errors.*;	
	import flash.net.*;	
	import fl.video.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;	
	import flash.net.LocalConnection;		
	
	import net.treecom.AppController;	
	import net.treecom.view.MediaBoxView;	
	import net.treecom.model.PlaylistModel;
	import net.treecom.model.PlaylogModel;
	import net.treecom.event.ModelEvent;
	import net.treecom.event.PlayerEvent;
	import net.treecom.utils.NetClient;
	
	import caurina.transitions.*;
	
 	public class PlayerController extends AppController {
		
		public var vp:Video;
		public var stream:NetStream;		
		private var connection:NetConnection;
		private var transformer:SoundTransform;
		private var pl:PlaylistModel;
		private var pllog:PlaylogModel;	
		private var checkTimer:Timer;
		private var timeOutTime:Number = 10000;
		private var timeOut:Number = 0;		
		private var ready:Boolean = false;
		private var volume:Number = 1;
		
		public function PlayerController(_view:MediaBoxView, _config:Object):void {
			super(_view, _config);			
			config.log('VideoPlayer initializing..');			 			
			volume = config.volume;
			initPls();
   		}
		 
		private function initPls():void {
 			
			// playlist			
			if (pl){				
				pl.removeEventListener(ModelEvent.LOADED, plsReady);
				pl.removeEventListener(ModelEvent.IOERROR, plsLoadingError);
				pl = null;
			}
			
			pl = new PlaylistModel(config);
			pl.addEventListener(ModelEvent.LOADED, plsReady, false,0,true);
			pl.addEventListener(ModelEvent.IOERROR, plsLoadingError, false,0,true);
			
			// played items loger
			pllog = null;
			pllog = new PlaylogModel(config);
		}
		
		private function initConnection():void {
			
			if (connection){
				try {
					connection.removeEventListener(NetStatusEvent.NET_STATUS, statusHandler);
            		connection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
					connection = null;
				} catch(e:Error){}
			}
			
			connection = new NetConnection();
			connection.addEventListener(NetStatusEvent.NET_STATUS, statusHandler);
            connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			connection.connect(null);
		}
		
		private function initStream():void{
				
				if (stream){
					try {
						stream.removeEventListener(NetStatusEvent.NET_STATUS, statusHandler);
						stream.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
						stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler);
						stream.close();
						stream.client = null;
						transformer = null;
						stream = null;	
						forceGC();
					} catch (e:Error){}
				}
			
				stream = new NetStream(connection);
				stream.addEventListener(NetStatusEvent.NET_STATUS, statusHandler, false,0,true);
				stream.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false,0,true);
				stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler, false,0,true);
				stream.bufferTime = config.playerBufferTime;
				stream.client = new NetClient(this);
				transformer = new SoundTransform();
 				
				if (checkTimer){
					try {
						checkTimer.stop();
						checkTimer.removeEventListener(TimerEvent.TIMER, checkTimerEvent);
						checkTimer = null;
					} catch(e:Error){}
				}
				checkTimer = new Timer(1000);
				checkTimer.addEventListener(TimerEvent.TIMER, checkTimerEvent, false,0,true);
				checkTimer.start();
 		}
		
		private function initPlayer():void {
			
			config.log('VideoPlayer initPlayer');
    			
			try {
				
				if (vp){
					try {						
						view.remove(vp);						
 						vp = null;
						forceGC();
					} catch (e:Error){}
				}
				
 				
				vp = new Video(config.width, config.height);
				vp.smoothing = config.playerSmoothing; // false with GPU!
				vp.alpha = 0;
				vp.attachNetStream(stream);													
				  				
				view.add(vp, true);
				
				vp.width = config.width;
				vp.height = config.height;
				vp.x = config.x;
				vp.y = config.y;
				
				vp.addEventListener(Event.ENTER_FRAME, vpEnterFrame);
				
				setVolume(volume);
 				
				if (!ready){
					dispatchEvent(new PlayerEvent(this, PlayerEvent.READY));
					ready = true;
				}
  				
			}catch (e:Error){
				config.log('VideoPlayer init ERROR:' + e);
			}			
		}
		
		public function onClientData(dat:Object):void {
			config.log('VideoPlayer onClientData'); 			
 		}
 
		public function vpEnterFrame(e:Event){
			if (vp.videoWidth>0){				
				if (config.ratio==true){
					
					// example 16:9
					if (config.width>config.height){
						// video ratio value
						var vr:Number = vp.videoWidth/vp.videoHeight;
						// set ratio
						vp.width = config.width;
						vp.height = config.width/vr;
					}
					
					// example 9:16
					if (config.width<config.height){
						// video ratio value
						var vr:Number = vp.videoHeight/vp.videoWidth;
						// set ratio
						vp.width = config.width/vr;
						vp.height = config.height;
					}
					
					
					// center
					if(config.width != vp.width) vp.x = (config.width - vp.width)/2;
					if(config.height != vp.height) vp.y = (config.height - vp.height)/2;
				}
				
				trace('video size:', vp.videoWidth, vp.videoHeight);
				trace('vp size:', vp.width, vp.height);
				trace('config size:', config.width, config.height);
				
				vp.removeEventListener(Event.ENTER_FRAME, vpEnterFrame);
			}
		}
		/** Receive NetStream status updates. **/
		protected function statusHandler(evt:*):void {
  			
			// trace('video size:', vp.videoWidth, vp.videoHeight);
			
 			switch (evt.info.code) {
				
				case "NetConnection.Connect.Success":
 					
					initStream();
					initPlayer();
					load();
                    
					break;
					
				case "NetStream.Play.StreamNotFound":
					
					config.log('VideoPlayer media not found!');
					playNext();
					
					break;
					
				case "NetStream.Play.Start":
 				
					if (config.playerClipTween){
						vp.alpha = 0;
						Tweener.addTween(vp, {alpha:1, time:0.3, delay:0, transition:"linear"});
					} else {
						vp.alpha = 1;
					}
					
					setTimeout(true);
					dispatchEvent(new PlayerEvent(this, PlayerEvent.PLAY));
					
					break;			
					
				case "NetStream.Play.Stop":
					
					pllog.logItem(pl.item);
					playNext();
					
					break;			
					
				case "NetStream.Play.StreamNotFound":
					config.log('Video not found or access denied: ' + pl.item.file);
					setTimeout();
					
					break;
			}						
		}
		
 		private function plsReady(e:ModelEvent):void {
			config.log('VideoPlayer playlist ready..');			
			pl.removeEventListener(ModelEvent.LOADED, plsReady);
			pl.removeEventListener(ModelEvent.IOERROR, plsLoadingError);	
 			dispatchEvent(new PlayerEvent(this, PlayerEvent.PLAYLIST));			
			initConnection();			
 		}
		
		private function plsLoadingError(e:*):void {
			config.log('VideoPlayer error on loading playlist..');		
			pl.removeEventListener(ModelEvent.LOADED, plsReady);
			pl.removeEventListener(ModelEvent.IOERROR, plsLoadingError);	
		}
	  
		private function errorHandler(evt:ErrorEvent):void {			
			config.log('VideoPlayer error: '+ evt.text)
		}
		
		public function playNext():void {
 			setTimeout();
			pl.next();					 
			initPlayer();
			load();
		}
		 
		public function load(item:String = ''):void {		
 			if (item=='' || item==null || !item && pl.item){
				item = pl.item.file_name;
			}
 			
			try {				
 				config.log('VideoPlayer loading: '+ item);				
				stream.checkPolicyFile = true;
				stream.play(getItemUrl(item));
  			} catch (e:*) {				
				config.log('VideoPlayer loading Error:' + item);
				config.log(String(e));
  				playNext();		
			}			
		}
 		
		public function getItemUrl(item:String = ''):String {
  			// bug fix:if one video only played player stop at end and dont rewind, so we change url (folder!) always on load, this solve problem 
			// this fix need rule in .htaccess
			var tm:String = (new Date()).time.toString();
 			return config.domain + config.media_folder + tm + '/' + item;;			
		}
 		 
		public function setVolume(level:Number = -1):void {
									
			transformer.volume = volume = level<0 ? volume : level;
			
			if (stream) {
				stream.soundTransform = transformer;
			}
		}
  		 
 		private function checkTimerEvent(e:TimerEvent):void{
			checkTimeout();
		}
		
		private function checkTimeout():void {
			var timeOutNow:Number = (new Date()).time;
			if ((timeOutNow-timeOut)>(timeOutTime) && timeOut>0){
				config.log('VideoPlayer idle timeout:'+ String(timeOutNow-timeOut));								
				initStream();
				playNext();
			}
		}
		
		private function setTimeout(reset:Boolean = false):Number {
			if (!reset){				 
				timeOut = (new Date()).time;
			} else {
				timeOut = 0;
			}
			return timeOut;
		}
		
		public function clickEvent(e:MouseEvent):void {			
			config.log('Click');
		}
		
		public function keyEvent(e:KeyboardEvent):void {
			// e.keyCode = 38 up - 39 right - 40 down - 37 left - 32 spacebar
			
			var step:Number = 10;
			
 			switch (e.keyCode){
				
				case 39: // right
					stream.seek(stream.time + step);
				break;
				
				case 37: // left
					if ((stream.time - step)>=0) stream.seek(stream.time - step);
				break;
				
				case 32: // spacebar
				/* @todo: commented - stream.playing not exist in stream
					if (stream.playing){
						stream.pause();
					} else {
						stream.play();
					}					
					*/
				break;
			}
		}
		
		private function forceGC():void {			
			try {
				new LocalConnection().connect('foo');
				new LocalConnection().connect('foo');
				System.gc();
			} catch (e:*) {}
		}
 	}	
}
