package net.treecom.controller {
	
	import flash.system.System;
	import flash.events.*;
	import flash.display.*;	
	import fl.video.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;	
	import flash.net.LocalConnection;
	import flash.errors.IOError;
	import flash.utils.Timer;
	
	import net.treecom.AppController;	
	import net.treecom.view.MediaBoxView;
	import net.treecom.view.PlayerView;		
	import net.treecom.model.PlaylistModel;
	import net.treecom.model.PlaylogModel;
	import net.treecom.event.ModelEvent;
	import net.treecom.event.PlayerEvent;
	
	import caurina.transitions.*;
	
 	public class PlayerController extends AppController {
		
		public var vp:FLVPlayback;				
		private var pl:PlaylistModel;
		private var pllog:PlaylogModel;	
		private var timeOutTime:Number = 10000;
		private var timeOut:Number = 0;
		private var checkTimer:Timer;
		
		public function PlayerController(_view:MediaBoxView, _config:Object):void {
			super(_view, _config);			
			
			config.log('VideoPlayer initializing..');
 		 	
			initPls();
 			initPlayer();
  		}
		 
		private function initPls():void {
 			// playlist
			pl = null;
			pl = new PlaylistModel(config);
			pl.addEventListener(ModelEvent.LOADED, plsReady, false,0,true);
			pl.addEventListener(ModelEvent.IO_ERROR, plsLoadingError, false,0,true);
			
			// played items loger
			pllog = null;
			pllog = new PlaylogModel(config);
		}
		
		private function initPlayer():void {
			
			removePlayer();
			
 			vp = new FLVPlayback();			
			vp.autoPlay = false;
			vp.autoRewind = false;
			vp.volume = config.volume;
			vp.alpha = 0;
			vp.fullScreenBackgroundColor = 0x000000;
			vp.fullScreenTakeOver = false;
			vp.x = config.x;
			vp.y = config.y;
			vp.width = config.width;
			vp.height = config.height;
			vp.setSize(vp.width, vp.height);
			vp.scaleMode = VideoScaleMode.NO_SCALE;
 			
			view.add(vp, true);
			
			vp.addEventListener(LayoutEvent.LAYOUT, layout, false,0,true);
			vp.addEventListener("ready", ready, false,0,true);
			vp.addEventListener("stateChange", stateChange, false,0,true);
			vp.addEventListener("bufferingStateEntered", bufferingEvent, false,0,true);
			vp.addEventListener("playingStateEntered", startPlay, false,0,true);			
			vp.addEventListener("playheadUpdate", playheadUpdate, false,0,true);			
			vp.addEventListener("stoppedStateEntered", endPlay, false,0,true);
			vp.addEventListener("complete", endPlay, false,0,true);
			vp.addEventListener("close", endPlay, false,0,true);
 			
			if (!checkTimer){
				checkTimer = new Timer(1000);
				checkTimer.addEventListener(TimerEvent.TIMER, checkTimerEvent, false,0,true);
				checkTimer.start();
			}
			
			setTimeout();
		}
		
		private function removePlayer():void {
			try {
				if (vp){
					vp.removeEventListener(LayoutEvent.LAYOUT, layout);
					vp.removeEventListener("ready", ready);
					vp.removeEventListener("stateChange", stateChange);
					vp.removeEventListener("bufferingStateEntered", bufferingEvent);
					vp.removeEventListener("playingStateEntered", startPlay);			
					vp.removeEventListener("playheadUpdate", playheadUpdate);			
					vp.removeEventListener("stoppedStateEntered", endPlay);
					vp.removeEventListener("complete", endPlay);
					vp.removeEventListener("close", endPlay);
					vp.stop();
					vp.getVideoPlayer(0).close();
					vp.closeVideoPlayer(0);
					view.remove(vp);					
					vp = null;
					
					checkTimer.stop();
					checkTimer.removeEventListener(TimerEvent.TIMER, checkTimerEvent);
					checkTimer = null;
					
					forceGC();
				}
			} catch (e:*){
			}
		}
		
 		private function plsReady(e:ModelEvent):void {
			config.log('VideoPlayer playlist ready..');			
			pl.removeEventListener(ModelEvent.LOADED, plsReady);
			pl.removeEventListener(ModelEvent.IO_ERROR, plsLoadingError);	
			load();
			dispatchEvent(new PlayerEvent(this, PlayerEvent.PLAYLIST));			
 		}
		
		private function plsLoadingError(e:*):void {
			config.log('VideoPlayer error on loading playlist..');		
			pl.removeEventListener(ModelEvent.LOADED, plsReady);
			pl.removeEventListener(ModelEvent.IO_ERROR, plsLoadingError);	
		}
		
		private function bufferingEvent(e:*):void {
			config.log('VideoPlayer buffering..');
			setTimeout();
		}
		
		private function ready(e:*):void {			
			config.log('VideoPlayer ready..');
			vp.enterFullScreenDisplayState();
			setTimeout();
			dispatchEvent(new PlayerEvent(this, PlayerEvent.READY));
		}
		
		private function stateChange(e:*){
			
			config.log('VideoPlayer state:' + e.state);
			
			if (e.state=="connectionError"){
				config.log('VideoPlayer connectionError:' + pl.item.file_name);	
				pl.next();
				load();
			}	

			if (e.state!="playing"){
				setTimeout();
			} else {
				setTimeout(true);
			}			
		}
		
		private function layout(e:LayoutEvent):void {
			config.log('VideoPlayer rendered..');
			setTimeout();
		}
		
		private function startPlay(e:*){			
		
			config.log('VideoPlayer play: '+ pl.item.file_name);			 
			
			if (config.playerClipTween){
				vp.alpha = 0;
 				Tweener.addTween(vp, {alpha:1, time:0.3, delay:0, transition:"linear"});
			} else {
				vp.alpha = 1;
			}
			
			dispatchEvent(new PlayerEvent(this, PlayerEvent.PLAY));
		}
		
		private function playheadUpdate(e:*):void {			
			if ((vp.totalTime-e.playheadTime)<0.4 && config.playerClipTween){
				Tweener.addTween(vp, {alpha:0, time:0.3, delay:0, transition:"linear"});
			} 
		}
		
		private function endPlay(e:*):void{
			config.log('VideoPlayer playback end');			 
 			pl.next();
			load();
			pllog.logItem(pl.item);
 		}
		 
		public function load(item:String = ''):void {		
 			if (item=='' || item==null || !item && pl.item){
				item = pl.item.file_name;
			}
 			
			try {				
 				config.log('VideoPlayer loading: '+ item);
				initPlayer();
				vp.play(getItemUrl(item));
 			} catch (e:*) {				
				config.log('VideoPlayer loading Error:' + item);
				config.log(String(e));
  				pl.next();
				load();				
			}			
		}
 		
		public function getItemUrl(item:String = ''):String {
  			// bug fix:if one video only played player stop at end and dont rewind, so we change url (folder!) always on load, this solve problem 
			// this fix need rule in .htaccess
			var tm:String = (new Date()).time.toString();
 			return config.domain + config.media_folder + tm + '/' + item;;			
		}
		
		public function clickEvent(e:MouseEvent):void {			
			config.log('Click');
		}
		
		public function keyEvent(e:KeyboardEvent):void {
			// e.keyCode = 38 up - 39 right - 40 down - 37 left - 32 spacebar
			
			var step:Number = 20;
			
 			switch (e.keyCode){
				
				case 39: // right
					vp.seekSeconds(vp.playheadTime + step);
				break;
				
				case 37: // left
					vp.seekSeconds(vp.playheadTime + step);
				break;
				
				case 32: // spacebar
					if (vp.playing){
						vp.pause();
					} else {
						vp.play();
					}					 
				break;
			}
		}
		
		public function get player():FLVPlayback {
			return vp;
		}
		
		private function checkTimerEvent(e:TimerEvent):void{
			checkTimeout();
		}
		
		private function checkTimeout():void {
			var timeOutNow:Number = (new Date()).time;
			if ((timeOutNow-timeOut)>(timeOutTime) && timeOut>0){
				config.log('VideoPlayer idle timeout:'+ String(timeOutNow-timeOut));				
				initPlayer();
				load();
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
		
		private function forceGC():void {			
			try {
				new LocalConnection().connect('foo');
				new LocalConnection().connect('foo');
				System.gc();
			} catch (e:*) {}
		}
 	}	
}
