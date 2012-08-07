package net.treecom.view  {
 
 	import flash.events.*;		
	import fl.events.*;
 	import flash.display.*;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.fscommand;
	
	import net.treecom.AppView;
	import com.adobe.utils.ArrayUtil;
	import caurina.transitions.*;
  	
	public class MediaBoxView  extends AppView {
 		
		private var views:Array = new Array();
		public var app:MovieClip;
		public var config:Object;
		private var alert:UIAlert;
		private var alertLast:String = '';
		private var fullscreen:Boolean = false;
 		
		public function MediaBoxView(_app:MovieClip, _config:Object):void {
			super();
			app = _app;
			config = _config;			
			app.stage.align = "TL";
			app.stage.scaleMode = StageScaleMode.NO_SCALE;
		}	
		
		
		public function add(disp:*, render:Boolean = false):void{
 			views.push(disp);
			if(render){
				renderView();
			}			
		}
		
		public function remove(disp:*):Boolean{
			if (views.length>0){
				if (app.removeChild(disp)){					
					ArrayUtil.removeValueFromArray(views, disp);
					return true;
				}
			}
			return false;
		}
		
		public function renderView():void{
			if (views.length>0){				
				for(var i:* in views){
					if (!app.contains(views[i])){
 						app.addChild(views[i]);
					}
				}
			}
		}
		
		public function fullScreen():void{
			app.stage.fullScreenSourceRect = new Rectangle(0,0, Number(config.width), Number(config.height));
			fullscreen = fullscreen ? false : true;
			fscommand('fullscreen', fullscreen ? 'true' : 'false');
		}
		
		public function showAlert(_msg:String, _title:String = 'Info', adding:Boolean = false):void {			
			
			alertCreate();
					
			if (alert && _msg){
				
				alert.alpha = 1;
				alert.name = 'alert';
				
				if (adding){
					alert.msg.text = alertLast + '\n' + alert.msg.text;					
				} else {
					alert.msg.text = _msg;
				}				
				
				alertLast = _msg;
				
				if (_title){
					alert.title.text = _title;
				}
				 
				Tweener.addTween(alert, {alpha:0, time:1, delay:5, transition:"linear"});
			}			
		}
		
		private function alertCreate():void {
			
			if (!alert || alert == null){
				alert = new UIAlert();
				alert.name = 'alert';
			} else {
				if (app.getChildByName('alert')) app.removeChild(alert);
			}
			
			alert.alpha = 0;
			app.addChild(alert);
			Tweener.addTween(alert, {alpha:.8, time:.3, delay:0, transition:"linear"});			
		}
		 		
		public function hideAlert():void {
 			if (app.getChildByName('alert')) {
				app.removeChild(alert);
				alert = null;				
			}
		}		 
	}	
}