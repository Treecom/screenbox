package net.treecom.controller {
        
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
	import net.treecom.view.*;
	import net.treecom.model.*;
	import net.treecom.controller.AudioPlayerClient;
	import net.treecom.utils.NetClient;
	

    public class AudioPlayerController extends AppController {
        
		public var streamURL:String = null;	
		private var reStreamer:String = null;	
        private var connection:NetConnection;
        private var netstream:NetStream;
		private var transformer:SoundTransform;
		private var player:Video;
		
        public function AudioPlayerController(__view:MediaBoxView, _config:Object):void {			
			super(__view, _config);
        }
		
		private function init():void {
 
 			config.log('AudioPlayer init');
			
 			if (connection){
				connection.close();
				connection.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            	connection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);				
				connection = null;
			}
			
          	connection = new NetConnection();
            connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);			
			connection.connect(null);
		}
		
  
        private function connectStream():void {
			
			
			if (config.streamAudioProxy==true){
				// reStreamer = config.domain + '/streamer.php?link='+ escape(streamURL);
				reStreamer = 'http://mediabox/streamer.mp3';
			} else {
				reStreamer = streamURL;
			}
			
			config.log('AudioPlayer conect:' + reStreamer);
			
			transformer = new SoundTransform();
			transformer.volume = 1;
			
            netstream = new NetStream(connection);
			netstream.checkPolicyFile = true;
			// netstream.bufferTime = config.streamAudioBuffer>0 ? config.streamAudioBuffer : 1000;
			netstream.bufferTime = 1;            
            netstream.client = new NetClient(this);			
			netstream.soundTransform = transformer;
			netstream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			netstream.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			netstream.play(reStreamer);
			
			player = new Video();
			player.attachNetStream(netstream);			
        }
		
		private function netStatusHandler(event:*):void {
			
			config.log("AudioPlayer status: " + event.info.code);
			
            switch (event.info.code) {
                case "NetConnection.Connect.Success":
                    config.log('NetConnection.Connect.Success');
					connectStream();					
                    break;
                case "NetStream.Play.StreamNotFound":
                    config.log("Stream not found: " + reStreamer);
                    break;
            }	
			// connection.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
        }
		
		public function stream(_streamURL:String = null):void {
			
			if (_streamURL!=null && _streamURL!=''){
					streamURL = _streamURL;
			}
				
			try {
				if (streamURL!=null) {
					init();
				}
 			} catch (e:*){
				config.log('AudioPlayer stream error:' + e);
			}
		}
 
		private function errorHandler(event:Error):void {
            config.log("AudioPlayerController ERROR: " + event);			 
        }
		
		public function onClientData(dat:Object):void {
			config.log('AudioPlayerController onClientData'); 			
 		}
		
		public function stop():void {
			if (netstream){
				netstream.close();
			}
		}
    }
}