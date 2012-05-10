package com.flotype.bridge {
	import flash.utils.Dictionary;
	
	/**
	 * Reference is the internal Bridge representation of a remote
	 * object containing a set of methods that correspond to an RPC
	 * API.
	 * 
	 * @author Ian Serlin
	 */	
	public dynamic class Reference extends Dictionary {
		
//		protected var _address:Array;
//		protected var _operations:Array;
//		protected var _bridge:Bridge;
		
		/**
		 * Constructor 
		 * 
		 * @param bridge The Bridge instance that owns this reference instance
		 * @param address the address that specifies this reference instance
		 * @param operations (optional) The array of string names that represent callable methods on this reference instance
		 */		
		public function Reference(bridge:Bridge, address:Array, operations:Array=null){
			super(false);
			try{
				this["_address"] = [];
				this._address = address.concat();
			}catch(e:Error){
				trace('llamas');
			}
			// For each supported operation, create a dummy function 
			// callable by user in order to start RPC call
			for(var i:int; i < operations.length; i++){
				var op:String = operations[i];
				if( op ){
					this[op] = _createWrapper(op);
						
//					(function(ref:Reference, op:String):* {
//						return function(...args):* {
//							ref._call(op, args);
//						}
//					}(this, op));
				}
			}
			// Store operations supported by this reference if any
			this._operations = operations ? operations : [];
			this._bridge = bridge;
		}
		
		protected function _createWrapper(operation:String):Function {
			var self:Reference = this;
			return function(...args):* {
				self._call( operation, args );
			}
		}
		
		/**
		 * 
		 * @param op
		 * @return 
		 */		
		public function _toDict(op:String=null):Object {
			// Serialize the reference
			var result:Object = {};
			var address:Array = this._address;
			// Add a method name to address if given
			if( op ){
				address = address.concat();
				address.push(op);
			}
			result.ref = address;
			// Append operations only if address refers to a handler
			if( address.length < 4 ){
				result.operations = this._operations;
			}
			return result;
		}
		
		public function _call(op:String, args:Array):void {
			Util.info('Calling', this._address + '.' + op);
			var destination:Object = this._toDict(op);
			this._bridge.send(args, destination);
		}
	}
}