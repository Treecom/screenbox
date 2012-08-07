package net.treecom.controller {
    
	import flash.events.Event;
    import flash.events.NetStatusEvent;
    import flash.events.SecurityErrorEvent;        
	import flash.events.IOErrorEvent;	
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.media.SoundChannel;
	
	import net.treecom.AppController;
	import net.treecom.view.*;
	import net.treecom.model.*;	
	
		
    public class AudioPlayerController extends AppController {
        
		private var streamURL:String = "http://scfire-dtc-aa03.stream.aol.com:80/stream/1026";		
        private var sound:Sound;
		private var channel:SoundChannel;
		
        public function AudioPlayerController(_view:MediaBoxView, _config:Object):void {			
			super(_view, _config);			
						
			if (config.streamAudio){
				if (config.streamAudio!=''){
					streamURL = config.streamAudio;
				}
			}
			
			sound = new Sound();
			sound.addEventListener(Event.COMPLETE, completeHandler);
			sound.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			sound.addEventListener(Event.OPEN, openHandler);
			sound.addEventListener(Event.ID3, id3Handler);
			sound.addEventListener(ProgressEvent.PROGRESS, progressHandler);
         }
		
		public function stream(_streamURL:String = null):void {	
 			if (_streamURL!=null){
				streamURL = _streamURL;
			}
			if (streamURL!=null){
 				try {
					config.log('AudioPlayer initilize stream');
					var req:URLRequest = new URLRequest(streamURL);
					sound.load(req); 
					channel = sound.play(0, 0, new SoundTransform(1, 0)); 
					channel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
 				} catch (e:*){
					config.log('AudioPlayer initilize Error' + e);
				}
			}
		}
 
 		private function progressHandler(e:Event):void {
            config.log('AudioPlayer bufering...');
        }
		
		private function completeHandler(e:Event):void {
            config.log('AudioPlayer loaded');
        }
		
		private function soundCompleteHandler(e:Event):void {
            config.log('AudioPlayer soundCompleteHandler');
        }
		
        private function openHandler(e:Event):void {
            config.log('AudioPlayer open');
        }
 
		private function id3Handler(e:Event):void {
            config.log('AudioPlayer ID3: ' + e);
        }
		
		private function ioErrorHandler(e:IOErrorEvent):void {
            config.log("AudioPlayer IO Error: " + e);
        }
    }
}