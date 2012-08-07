<?php

/**
 * Streamer - streaming proxy for flash 
 */

ini_set('output_buffering', "0");
// set_time_limit(64*3600);
set_time_limit(60*10);

 
if (!empty($_REQUEST['link'])){
		
	$tlink = trim(urldecode($_REQUEST['link']));
	$link = parse_url($tlink);		
	$server = $link['host'];
	$path = empty($link['path']) ? '/' : $link['path']; 
	$port = empty($link['port']) ? 80 : intval($link['port']);	
	$fp = fsockopen($server, $port, $errno, $errstr, 120);
	
	if (!empty($_REQUEST['content'])){
		$contentType = trim($_REQUEST['content']);
	} else {
		// default
		$contentType = 'audio/mpeg';
	}
	
	if ($fp) {
			header("Content-type: " . $contentType);
		 	ob_end_flush();
			
			fputs($fp, "GET $path  HTTP/1.0\r\n");
			fputs($fp, "Host: $server\r\n");
			fputs($fp, "Accept: */*\r\n");		
			fputs($fp, "Connection: close\r\n\r\n");			
		 	
	        while (!feof($fp)) {				 
 				print fgets($fp, 4096);				 
	        }
	        fclose ($fp);
			
	} else echo "Connection error!"; 
}  