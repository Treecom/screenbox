<?php 
/**
 *  Player component
 *
 *  @author Martin Bucko (bucko at treecom dot net)
 *  @copyright Copyright 2010 - 2011 Treecom s.r.o.
 *  @version 1.0
 *  @created 26.08.2010
 *  @modified 26.08.2010
 */
 
class PlayerComponent extends Object {

    /**
     * @var string Component name
     */
    var $name = "Player";
    
    /**
     * @var array Load other components for use
     */
    var $components = array();
	
	/**
	 * Player config
	 */
    var $config = array(
		'playlist' => 'http://localhost/playlist',
		'playlistCache' => '',
		'logfile' => '' 
	);
	
	var $playerConfig = array();
	var $settings = array();
	var $controller;
	
    /**
     * __construct
     * Constructor load model page
     * @return
     */
    function __construct() {
   		
    }
    
    /**
     * init
     * Used to initialize the components for current controller.
     * @params object Controller with components to load
     * @return void
     */
    function init(&$controller) {
    	$this->controller = $controller;		
    }
    
    /**
     * initilize
     * The initialize method is called before the controller's beforeFilter method.
     * @params object $controller with components to initialize
     * @return void
     */
    function initialize(&$controller, $settings = array()) {
    	$this->controller = $controller;
		$this->settings = $settings;
		$this->configure($settings);
    }
    
    /**
     * shutdown
     * The shutdown method is called before output is sent to browser.
     * @param object $controller
     * @return void
     */
    function shutdown(&$controller) {
    	
    }
	
	function stop(){
		return $this->send('stop');
	}
	
	function pause(){
		return $this->send('pause');
	}
	
	function playlistRestart(){
		
 		// return shell_exec('curl -s http://localhost/playlist > ' . $this->config['playlistCache']);
	}
	
	
	function playlistClear(){
		return  $this->playlistRestart();
	}
	
	function add($path, $append = 1){
		return null;
	}

	function send($commands_array = array(), $ip = 'localhost', $port = 8000, $udelay = 500000) {
		if (is_array($commands_array)){
			foreach((array) $commands_array as $k=>$v){
				$commands_array[$k] = 'f '.$v;
			}
		} else {
			$commands_array = 'f '.$commands_array; 
		}
		return false;
	}
    
    /**
	* Run start_smplayer
    */
    function startPlayer() {
		return shell_exec('nohup /var/www/start_player > /dev/null 2>&1 & echo $!');
		// return shell_exec('/var/www/start_player');
    }
	
	function configure($settings = null){
		$this->config['logFile'] = TMP.'/player-log';
		$this->config['playlistCache'] = TMP.'/pls.json';
		
		return $this->playerConfig = array(
			
		);
	}
	
	function clear(){
		
	}
	
	function getKey(){
		$key = Configure::read('MediaServerBoxKey');
		if (empty($key)){
			$key = file_get_contents(TMP.'/mac');
			$key = str_replace(':', '', strtolower(trim($key)));
		}
		return $key;
	}
}
