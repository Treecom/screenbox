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
        private var currentSound:Sound;
		private var sound1:Sound;
		private var channel1:SoundChannel;
		private var sound2:Sound;
		private var channel2:SoundChannel;
		private var soundToggle:Boolean = false;		
		private var context:SoundLoaderContext;
		private var transformer:SoundTransform;		
		public var id3:ID3Info;
		private var disabled:Boolean = false;
		private var loadTimer:Timer;
		private var initialized:Boolean = false;
		
        public function AudioPlayerController(_view:MediaBoxView, _config:Object):void {			
			super(_view, _config);
          }
		
		public function init():void {
			
			if (!initialized){
				if (config.streamAudio){
					if (config.streamAudioUrl!=''){
						streamURL = config.streamAudioUrl;
					}
				}
				
				clearSound(sound1, channel1);
				clearSound(sound2, channel2);
				
				context = new SoundLoaderContext(0, true);
				transformer = new SoundTransform(config.streamAudioVolume);
				
				sound1 = initSound();
							
				// prevent memory leaks restart
				if (loadTimer==null){
					loadTimer = new Timer(1000*60*10);
					loadTimer.addEventListener(TimerEvent.TIMER, timerLoadEvent, false,0,true);
					loadTimer.start();
				}
				initialized = true;
			}
		}
		
		
		function initSound():Sound {
			var snd:Sound = new Sound();
			snd.addEventListener(Event.COMPLETE, completeHandler, false,0,true);
			snd.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler, false,0,true);
			snd.addEventListener(Event.OPEN, openHandler, false,0,true);
			// snd.addEventListener(Event.ID3, id3Handler, false,0,true);
 			return snd;
		}
		
		function clearSound(snd:Sound, channel:SoundChannel = null):void {
			
 			if (snd!=null){
				config.log('AudioPlayer clear sound');
				
				if (channel!=null){
					channel.stop();
				}
				
				snd.removeEventListener(Event.COMPLETE, completeHandler);
				snd.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				snd.removeEventListener(Event.OPEN, openHandler);					
				// snd.removeEventListener(Event.ID3, id3Handler);
				snd.close();
				snd = null;
				
			}			
 		}
		
		public function stream(_streamURL:String = ''):void {	
		
			disabled = false;
			
 			if (_streamURL!=null && _streamURL!=''){
				streamURL = _streamURL;
			}
			if (streamURL!=''){
 				
				init();
					
				if (config.streamAudioProxy==true){
					reStreamer = config.domain + '/streamer.php?link='+ escape(streamURL) + '&t='+((new Date()).getTime().toString());
				} else {
					reStreamer = streamURL;
				}
				config.log('AudioPlayer stream: ' + reStreamer);
				
				var req:URLRequest = new URLRequest(reStreamer);
				
				if (soundToggle){
					sound2.load(req, context); 										
					channel2 = sound2.play(0, 0, transformer);					
				} else {
					sound1.load(req, context); 										
					channel1 = sound1.play(0, 0, transformer);					
				}
			}
		}
		
		public function stop(_dis:Boolean = true):void {
			clearSound(sound1, channel1);
			clearSound(sound2, channel2);			
			disabled = _dis;
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
 			if (soundToggle){
 				clearSound(sound1, channel1);
			} else {				 
				clearSound(sound2, channel2);
			}
			 
        }

		private function id3Handler(e:Event):void {
			try {
				id3 = null;
				id3 = currentSound.id3;				
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
				swapSound();
			}
        }
		
		private function swapSound():void{
			
			config.log("AudioPlayer SWAP");
			
			soundToggle = !soundToggle;
			
			if (soundToggle){
				config.log("AudioPlayer togle 2");
 				sound2 = initSound();
				stream();
 			} else {
				config.log("AudioPlayer togle 1");
 				sound1 = initSound();
				stream();
 			}
 		}
		
		private function timerLoadEvent(e:TimerEvent):void{
			if (!disabled){
				swapSound();
			}
		}
    }
}