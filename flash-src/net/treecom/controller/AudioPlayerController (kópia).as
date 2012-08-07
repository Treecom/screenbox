package net.treecom.controller {
        
	import flash.events.*;	
	import flash.media.*;
	import flash.utils.*;
	import flash.errors.*;	
	import flash.net.*;	
    
	import net.treecom.AppController;
	import net.treecom.view.*;
	import net.treecom.model.*;
	import net.treecom.controller.AudioPlayerClient;
	

    public class AudioPlayerController extends AppController {
        
		public var streamURL:String = null;	
		private var reStreamer:String = null;	
        private var connection:NetConnection;
        private var netstream:NetStream;
		private var transformer:SoundTransform;
		
        public function AudioPlayerController(__view:MediaBoxView, _config:Object):void {			
			super(__view, _config);
			
			if (config.streamAudio){
				if (config.streamAudioUrl!=''){
					streamURL = config.streamAudioUrl;
				}
			}			
        }
		
		private function init():void {
 
 			if (connection){
				connection.close();
				connection.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            	connection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
 				connection = null;
			}
			
          	connection = new NetConnection();
            connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false,0,true);
            connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false,0,true);
 		}
		
		public function stream(_streamURL:String = null):void {
			
			if (_streamURL!=null && _streamURL!=''){
					streamURL = _streamURL;
			}
				
			try {
				init();				
            	connection.connect(null);
			} catch (e:*){
				config.log('AudioPlayer stream error:' + e);
			}
		}

   

        private function connectStream():void {
			config.log('AudioPlayer conect:' + streamURL);
			
			if (config.streamAudioProxy==true){
				reStreamer = config.domain + '/streamer.php?link='+ escape(streamURL);
			} else {
				reStreamer = streamURL;
			}
			
            netstream = new NetStream(connection);
			netstream.checkPolicyFile = true;
			// netstream.bufferTime = config.streamAudioBuffer>0 ? config.streamAudioBuffer : 1000;
			netstream.bufferTime = 1;
            netstream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false,0,true);
			netstream.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false,0,true);
            netstream.client = new AudioPlayerClient(this, config);
            netstream.play(reStreamer);
        }
		
		private function netStatusHandler(event:*):void {
			
			config.log("AudioPlayer status: " + event.info.code);
			
            switch (event.info.code) {
                case "NetConnection.Connect.Success":
                    config.log('NetConnection.Connect.Success');
					connectStream();					
                    break;
                case "NetStream.Play.StreamNotFound":
                    config.log("Stream not found: " + streamURL);
                    break;
            }	
			// connection.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
        }
 
		private function errorHandler(event:Error):void {
            config.log("AudioPlayerController ERROR: " + event);			 
        }
		
		public function stop():void {
			if (netstream){
				netstream.close();
			}
		}
    }
}