<?php

/**
 * MediaBox Model Class
 * 
 *  @author Martin Bucko, Treecom s.r.o.
 *  @copyright Copyright (c) 2011 Treecom s.r.o. All right reserved!
 *  @license Read /LICENSE.txt or http://raw.github.com/Treecom/screenbox/master/LICENSE.txt
 */

class MediaBox extends AppModel {
	/**
	 * @var string model name
	 */
	var $name = 'MediaBox';
	
	/**
	 * Model display field
	 * @var string
	 */
 	var $displayField = 'id';
	
	/**
	 * @var string (or array) The column name(s) and direction(s) to order find results by default.
	 */
	var $order = "MediaBox.id DESC"; 
	
 
 	var $useTable = 'media_boxes';
	/**
	 * Use this callback to modify results that have been returned from a find operation, or to perform any other post-find logic. 
	 * The $results parameter passed to this callback contains the returned results from the model's find operation.
	 * @param array $results
	 * @param boolean $primary
	 * @return array modified results
	 */
	function afterFind($results, $primary){		 
		if ($primary && !empty($results[0]['MediaBox']['config'])){
			$results[0]['MediaBox']['config'] = unserialize($results[0]['MediaBox']['config']);
		} 		 
		return $results;
	}
	
	/**
	 * Place any pre-save logic in this function. This function executes immediately after model data has been successfully validated, but just before the data is saved. This function should also return true if you want the save operation to continue.
	 * @return boolean 
	 */
	function beforeSave(){
		if (!empty($this->data['MediaBox']['config'])){
			if (is_array($this->data['MediaBox']['config'])){
				$this->data['MediaBox']['config'] = serialize($this->data['MediaBox']['config']);
			}
		}
		return true;
	}
  
	/**
	 * Called if any problems occur.
	 * Can be used allso for errors loging and etc.
	 * @return void
	 */
	function onError(){
		LogError('Error in model MediaBox!');
	}
}