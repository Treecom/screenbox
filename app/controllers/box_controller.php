<?php
/**
 *  Screenbox controller
 *
 *  This is main class to controll backend for Flash Player. Flash Player for security reasons dont cant use file system and sqlite database. For this we use very good framework CakePHP to maintain backend of Screen box client.
 * 
 *  NOTE: Some function is named like Media or MediaBox. This name is first project name and will be renamed in future versions.
 *
 *  @author Martin Bucko, Treecom s.r.o.
 *  @copyright Copyright (c) 2011 Treecom s.r.o. All right reserved!
 *  @license Read /LICENSE.txt or http://raw.github.com/Treecom/screenbox/master/LICENSE.txt
 *  @created 21.10.2011
 */

class BoxController extends AppController {

	/**
	 * @var string Controller name
	 */
	var $name = 'Box';
	
	/**
	 * @var array Default components
	 */
	var $components = array('Json');

	/**
	 * @var array Default helpers
	 */
	var $helpers = array();
	
	/**
	 * @var string Default layout
	 * @access public
	 */
	var $layout = 'blank';
	
	/**	 
	 * @var string Playlist local address	 
	 */
	var $playlist = 'http://localhost/playlist';

	/**
	 * @var string Server playlist link
	 */
	var $serverPlaylist = '';

	/**
	 * @var string Server download link
	 */
	var $serverDownLink = '';
	
	/**
	 * @var string Local media folder
	 */
	var $mediaFolder = '';

	/**	 
	 * @var string Default json file	 
	 */
	var $jsonFile =  '/get.json';

	/**
	 * @var boolean use diff
	 */
	var $diff = false;

	/**
	 * @var array  Use this Model classes.
	 */
	var $uses = array('MediaBox','Medias','MediaPlaytime','MediaPlaylog');
	
	/**
	 * Class constructor
	 * @return void
	 */
	function __construct() {
		parent::__construct();
	}
	
	/**
	 * This function is called before every page function in controller.
	 * @return void
	 */
	function beforeFilter(){
		$key = $this->__getKey();
		$this->mediaFolder =  APP . '/webroot/files/media/';
		$this->serverPlaylist =  Configure::read('MediaServerURL') . Configure::read('MediaServerPLaylist') . $key . $this->jsonFile;
		$this->serverDownLink =  Configure::read('MediaServerURL') . Configure::read('MediaServerDownload') . $key;
		$this->set('content', '');
	}
	
	/**
	 * Default index page
	 * @return void
	 */	
	function index(){ 
		$this->autoRender = false;
		$this->redirect(Configure::read('MediaServerURL'), 1);
		exit();
	}
	
	/**
	 * Playlist generator for Flash Player.
	 * @return void
	 */
	function playlist(){
	 
 		$media = array();
		$data =  $this->Medias->playlist();
		
 		if (!empty($data)){			
			foreach($data as $file){
				$play = false;
				if (empty($file['MediaPlaytime'])){
					$play = true;
				} else {
					foreach($file['MediaPlaytime'] as $pt){
						if ($play == false && $pt['time_from'] == intval(date('G').'00') && $pt['time_to'] == intval((date('G')+1).'00') 
							&& ($pt['day'] == date('N') || $pt['day'] == 0 || empty($pt['day']))){
								$play = true;
						}
					}
				}
				
				if ($play){
 					$media[] = $file['Medias'];
				}
			}
		} 
		if (empty($media)) {
 			$media[] = array('file_name'=> 'default.mp4');
		}
 
		$this->set('content', $media);
	}
	
	/**
	 * Data synchronizations from Screenbox server.
	 * @return void
	 */
	function sync(){
		
		$result = '';
		$ids = array();
		$reset = false;
		$this->MediaPlaylog->import(true);
		
		App::import('Core', 'HttpSocket');
		$HttpSocket = new HttpSocket();
		$data = $HttpSocket->post($this->serverPlaylist, $this->_stats());		

 		if (!empty($data)){
			$data = $this->Json->decodeToArray($data);
		}
		
 		if (!empty($data['mediaserver_playlist'])){
				
			$this->MediaPlaylog->sync(true); // mark all sync 1
			
			$data = $data['mediaserver_playlist'];	
			
			if (isset($data['Media'])){
				$result = "Saving:"; 
				$old_ids = $this->Medias->find('all', null, array('id','file_name'));
				
				$this->MediaPlaytime->deleteAll(array('id >'=>0));
				
				if (is_array($data['Media'])){
					foreach($data['Media'] as $medium){
						$medium = $this->Json->decodeToArray($medium, false);
	
						// save media data
						if (!empty($medium['id'])){
							 if ($this->Medias->save($medium)){
							 	$result .= $medium['id'] .',';
								$ids[] = $medium['id'];
								 
								 // save media play times
								if (!empty($medium['MediaPlaytime'])){ 	
								 	if (!empty($medium['MediaPlaytime'][0])){
								 		foreach($medium['MediaPlaytime'] as $mpt){
								 			$this->MediaPlaytime->save($mpt);
								 		}
								 	}
								}
							 }
						}
					}
				}
				
				// delete old videos				
				foreach($old_ids as $old){
					if (!in_array($old['Medias']['id'], $ids)){
						$file = $this->mediaFolder . $old['Medias']['file_name'];
						if (file_exists($file)){
							if (unlink($file)){
								if ($this->Medias->delete($old['Medias']['id'])){
									$reset = true;
								}
							}
						}
					}
				}
			}
			
			
			if (!empty($data['MediaBox'])){
				$this->MediaBox->deleteAll(array('id >' => 0));
				$this->MediaBox->save($data['MediaBox']);
			}
		}
		
 		
		$this->set('content', $result);
	}

	/**
	 * Media downloader for media files from Screenbox server.
	 * @return void
	 */
	function downloader(){
			 
		$result = '';
		$reset = false;
		$dfolder = $this->mediaFolder;
		 
		$opt = array('conditions'=> array('downloaded' => NULL));
		$medium = $this->Medias->find('first', $opt);
		$count = $this->Medias->find('count', $opt);
		$count_all = $this->Medias->find('count');
	
		if (!empty($medium['Medias']['file_path']) && !empty($medium['Medias']['file_name'])){
				
			$dm =  $this->mediaFolder . $medium['Medias']['file_name'];
			$url = $this->serverDownLink . '/media:'.$medium['Medias']['id'] . $this->jsonFile ;
			$cmd = 'nice wget -q -t 2 -c --no-cookies --no-cache -O '. $dm . ' '. $url;
			exec($cmd, $status1, $status2);

			// @todo add md5 check sum!!!
			if($status2===0 && file_exists($dm)){
				$this->Medias->save(array('id'=>$medium['Medias']['id'], 'downloaded'=>1));
				$result = 'media:'.$medium['Medias']['id'] .' - status: DOWNLOADED';
				if ($medium['Medias']['play']==1){
					// $this->Player->add($dm, true);
					$reset = true;
				}
			} else {
				$result = 'media:'.$medium['Medias']['id'] .' - status: FAIL';
			}
		}
 		
		$this->set('content', $result);
	}
	
	/**
	 * Generate stats. See _stats function.
	 * @return void
	 */
	function stats(){
		$this->autoRender = false;
		$result = $this->_stats();
		$result = print_r($result, true);
		$result = '<pre>' .$result;
		$this->set('content', $result);
		$this->render('sync');
	} 
	
	/**
	 * Restart flash player.
	 * @return void
	 */
	function restart(){
		$this->autoRender = false;
		$result = shell_exec('killall -9 flashplayer');
		$this->set('content', $result);
		$this->render('sync');
	}
	
	/**
	 * Obsolete function. Start player.
	 * @return void
	 */
	function start(){
		$this->restart();
	}

	/**
	 * Obsolete function. Call player commands.
	 * @return void
	 */
	function player($cmd = null){
		$result = '';
 		if (!empty($this->data['Medias']['cmd'])){
			$cmd = $this->data['Medias']['cmd'];
		}
		if (!empty($cmd)){
			// $cmd = preg_replace('/[^a-z0-9\-_ ]/i', '', $cmd);
			// $result = $this->Player->send($cmd);
		}
		$this->set('content', $result);
	}
	
	/**
	 * Config for Adobe Flash Player.Configuration is merged with defautl config and config from server.
	 * @return void
	 */
	function config(){
		$this->autoRender = false;
		$config = array(
 				"confInterval"=> (1000*30),
				"domain" => 'http://mediabox',
				"pls" => '/playlist',
				"plsReload" => (1000*30),
				"media_folder" => '/files/media/',
				"playlogUrl" => '/playlog',
				"playlogInterval" => (1000*60),
				"logerUrl" => '/loger',
				"width" => 1280,
				"height" => 720,
				"ratio"=>false,
				"x" => 0,
				"y" => 0,
				"volume" => 1,			
				"streamAudio" => false,	
				"streamAudioVolume" => 1,				
				"streamAudioUrl" => '',
 				"streamAudioProxy" => true, 				
				"loger" => true,
				"logToAlert" => false,
				"playerSmoothing" => false, // false fro GPU/HW decoding!
				"playerClipTween" => false
		);
		
		$box = $this->MediaBox->find('first', array(
			'conditions' => array('public'=>1)
		));
		
		if (!empty($box['MediaBox'])){
			if (!empty($box['MediaBox']['config']) && is_array($box['MediaBox']['config'])){
				$config = array_merge($config, $box['MediaBox']['config']);
			}
			unset($box['MediaBox']['config']);
			$config = array_merge($config, $box['MediaBox']);
		}
 
 		$this->set('content', array($config));
		$this->render('playlist');
	}

	/**
	 * Defult configuration. Used only for testing.
	 * @return void
	 */
	function conf(){
		$config = array(
				"volume" => 0,
				// "streamAudio" => "http://scfire-dtc-aa03.stream.aol.com/stream/1026",
				"streamAudio" => "http://scfire-mtc-aa04.stream.aol.com:80/stream/1007",
				//"streamAudio" => false,
				"loger" => true,
				"logToAlert" => false,
		);
		echo serialize($config);	
	}
 	

 	/**
	 * Generate stats from Screenbox.
	 * @param boolean 
	 * @return array stats output 
	 */
	function _stats($post = true){
		$out = array();
		
		$uptime = exec("cat /proc/uptime");
		$uptime = explode(" ",$uptime);
		$out['uptime'] = ceil($uptime[0]); // seconds
	  
	  	$load = exec("uptime");
		$load = explode('average:', $load);
		$load = explode(',',$load[1]);
	  	$out['cpu'] = trim($load[1]);
		
		
		$mem = shell_exec("cat /proc/meminfo");
		$mem = explode("\n", $mem);
		$keys = array('MemTotal','MemFree','SwapTotal','SwapFree','Cached');
		foreach($mem as $m){
			$m = explode(':',$m);
			if (in_array(trim($m[0]), $keys)){
				$k = trim($m[0]);
				if ($k=='Cached'){
					$k = "MemCached";
				}
				$k = Inflector::underscore($k);
				$out[$k] = intval($m[1]);
			}
		}
		
		$df = shell_exec('df -h | grep sda1 | awk \'{print $2,$3,$4,$5}\'');
		$df = explode(' ', $df);
		$out['disk_total'] = floatval($df[0]);
		$out['disk_used'] = floatval($df[1]);
		$out['disk_avail'] = floatval($df[2]);
		$out['disk_percent'] = floatval($df[3]);
		
				
		$proc = array('apache','flashplayer');
		foreach ($proc as $v){
			$out[$v] = exec('ps -Al | grep '.$v.'  | wc -l');
		}
		
		// to cake POST data format
		if ($post){
			$tmp = array();
			$tmp['MediaBoxLog'] = array();
			foreach($out as $key => $val){
				$tmp['data']['MediaBoxLog'][$key] = $val; 
			}
			$tmp['data']['MediaPlaytimeLog'] = $this->MediaPlaylog->sync();
			return $tmp;
		} else {
			return $out;
		}
	} 


	/**
	 * Function is obselete. used with old mplayer/vlc version.
	 * @return void
	 */
	function loger(){
		$this->autoRender = fasle;
		if (!empty($_GET['msg'])){
			$file = new File('/tmp/player.log');
			$file->append('['.date('H:i:s d.m.Y') . '] ' . trim($_GET['msg']) . "\n");
			$file->close();
		}
		$this->render('sync');
	}
	

	/**
	 * play log
	 * @return void
	 */
	function playlog(){
		$this->autoRender = fasle;
		if (!empty($_POST['savedata'])){
			$log = $_POST['savedata'];
			$log = $this->Json->decodeToArray($log);
			if (!empty($log['items'])){
				$log = $log['items'];
				if (is_array($log)){
					$out = $this->MediaPlaylog->import($log, true);							
				}
			}
		}
		$this->render('sync');
	}

	/**
	 * Get key for current client. Key is generated from MAC address or from Config file.
	 * @return string key
	 */
	function __getKey(){
		$key = Configure::read('MediaServerBoxKey');
		if (empty($key)){
			$key = file_get_contents(TMP.'/mac');
			$key = str_replace(':', '', strtolower(trim($key)));
		}
		return $key;
	}
}
