package com.flotype.bridge {
	import flash.events.Event;
	
	/**
	 * Bridge Socket Event class.
	 * 
	 * @author Ian Serlin
	 */	
	public class BridgeSocketEvent extends Event {
		
		public static const ON_MESSAGE:String = 'onMessage';
		
		public function get value():* {
			return _value;
		}
		protected var _value:*;
		
		public function BridgeSocketEvent(type:String, value:*=null, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
			_value = value;
		}
	}
}