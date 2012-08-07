package net.treecom.controller {
	import flash.events.*;
	import net.treecom.controller.AudioPlayerController;
	
	class AudioPlayerClient {
		private var config:Object;
		private var apc:AudioPlayerController;
		public function AudioPlayerClient(_apc:AudioPlayerController, _config:Object):void {
			apc = _apc;
			config  = _config;
		}
		public function onMetaData(info:Object):void {
			config.log("metadata: duration=" + info.duration + " width=" + info.width + " height=" + info.height + " framerate=" + info.framerate);
		}
		public function onCuePoint(info:Object):void {
			config.log("cuepoint: time=" + info.time + " name=" + info.name + " type=" + info.type);
		}
		public function onPlayStatus(info:Object):void {
			config.log("onPlayStatus: time=" + info.time + " name=" + info.name + " type=" + info.type);
		}
	}
}