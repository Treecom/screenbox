package net.treecom.controller {
    
	import flash.events.*;
    import flash.net.URLRequest;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.media.ID3Info;
	import flash.utils.Timer;
	
	import net.treecom.AppController;
	import net.treecom.view.*;
	import net.treecom.model.*;	
	import flash.net.URLVariables;
 		
    public class AudioPlayerController extends AppController {
        
		public var streamURL:String;		
		private var reStreamer:String;
        private var sound:Sound;
		private var channel:SoundChannel;
		private var context:SoundLoaderContext;
		private var transformer:SoundTransform;		
		public var id3:ID3Info;
		private var disabled:Boolean = false;
		private var loadTimer:Timer;
		
        public function AudioPlayerController(_view:MediaBoxView, _config:Object):void {			
			super(_view, _config);			
         }
		
		public function init():void {
			
			if (config.streamAudio){
				if (config.streamAudioUrl!=''){
					streamURL = config.streamAudioUrl;
				}
			}
			
 			if (sound){
				try {
					sound.close();
					sound.removeEventListener(Event.COMPLETE, completeHandler);
					sound.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
					sound.removeEventListener(Event.OPEN, openHandler);					
					// sound.removeEventListener(Event.ID3, id3Handler);
					// sound.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
					sound = null;
				} catch (err:Error) {
				}
			}
			
			if (channel){
				try {
					channel.stop();					
					channel = null;
				} catch (err:Error) {
				}
			}
			
			context = new SoundLoaderContext(config.streamAudioBuffer, true);
			transformer = new SoundTransform(config.streamAudioVolume);
 			sound = new Sound();
			sound.addEventListener(Event.COMPLETE, completeHandler, false,0,true);
			sound.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler, false,0,true);
			sound.addEventListener(Event.OPEN, openHandler, false,0,true);
			// sound.addEventListener(Event.ID3, id3Handler, false,0,true);
			// sound.addEventListener(ProgressEvent.PROGRESS, progressHandler, false,0,true);
			
			// prevent memory leaks restart
			if (loadTimer==null){
				//loadTimer = new Timer(1000*60*30); // 30 min
				//loadTimer.addEventListener(TimerEvent.TIMER, timerLoadEvent, false,0,true);
				//loadTimer.start();
			} 
		}
		
		public function stream(_streamURL:String = ''):void {	
		
			disabled = false;
			
 			if (_streamURL!=null && _streamURL!=''){
				streamURL = _streamURL;
			}
			if (streamURL!=''){
 				try {
					init();
					if (config.streamAudioProxy==true){
						reStreamer = config.domain + '/streamer.php?link='+ escape(streamURL);
					} else {
						reStreamer = streamURL;
					}
 					config.log('AudioPlayer initilize stream');
					config.log(reStreamer);
					
					var req:URLRequest = new URLRequest(reStreamer);
					sound.load(req, context); 
					channel = null;
					channel = sound.play(0, 0, transformer);					
					
 				} catch (e:*){
					config.log('AudioPlayer initilize Error' + e);
				}
			}
		}
		
		public function stop():void {
			channel.stop();
			sound.close();
			disabled = true;
		}
		
		public function play(_streamURL:String = ''):void {
			 stream(_streamURL);
		}
 
 		private function progressHandler(e:Event):void {
            config.log('AudioPlayer bufering...');
        }
		
		private function completeHandler(e:Event):void {
            config.log('AudioPlayer completeHandler');
			if (!disabled){
				stream();			
			}
        }
		
        private function openHandler(e:Event):void {
            config.log('AudioPlayer open');
        }

		private function id3Handler(e:Event):void {
			try {
				id3 = null;
				id3 = sound.id3;				
				var obj:Object = {
					 	type: 'id3',
				 		album: id3.album,
                        artist: id3.artist, 
						comment: id3.comment,
						genre: id3.genre, 
						name: id3.songName, 
						track: id3.track,
                        year: id3.year
				};
            	config.log('AudioPlayer play: ' + obj.songName);
			} catch (err:Error){				
			}
        }
		
		private function ioErrorHandler(e:IOErrorEvent):void {			
			config.log("AudioPlayer IO Error: " + e);
			if (!disabled){
				stream();
			}
        }
		
		private function timerLoadEvent(e:TimerEvent):void{
			stream();
		}
    }
}