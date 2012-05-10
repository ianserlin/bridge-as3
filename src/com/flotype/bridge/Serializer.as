package com.flotype.bridge {
	
	/**
	 * Abstracts Bridge specific (de)serialization of
	 * local and remote objects for transmission between
	 * Bridge clients and Bridge servers.
	 * 
	 * @author Ian Serlin
	 */	
	public class Serializer {
		
		/**
		 * Serializes an object into a format suitable for transmission 
		 * to a Bridge server.
		 * 
		 * @param bridge The Bridge instance you are serializing for
		 * @param pivot The object you want to serialize
		 * 
		 * @return The serialized object in the appropriate format for transmission to a Bridge server 
		 */		
		public static function serialize(bridge:Bridge, pivot:Object):* {
			var type:String = Util.typeOf(pivot);
			var result:*;
			switch(type) {
				case 'object':
					if (pivot === null) {
						result = null;
					} else if ('_toDict' in pivot) {
						result = pivot._toDict();
					} else {
						var funcs:Array = Util.findOps(pivot);
						if (funcs.length > 0) {
							result = bridge._storeObject(pivot, funcs)._toDict();
						} else {
							// Enumerate hash and serialize each member
							result = {};
							for (var key:String in pivot) {
								var value:* = pivot[key];
								result[key] = Serializer.serialize(bridge, value);
							}
						}
					}
					break;
				case 'array':
					// Enumerate array and serialize each member
					result = [];
					for (var i:int = 0, ii:int = pivot.length; i < ii; i++) {
						var val:* = pivot[i];
						result.push(Serializer.serialize(bridge, val));
					}
					break;
				case 'function':
					if ( Util.hasProp(pivot, '_reference') ) {
						result = pivot._toDict();
					} else {
						result = bridge._storeObject({callback: pivot}, ['callback'])._toDict();
					}
					break;
				default:
					result = pivot;
			}
			return result;
		}

		/**
		 * 
		 * @param bridge
		 * @param obj
		 * @return 
		 * 
		 */		
		public static function unserialize(bridge:Bridge, obj:Object):* {
			for( var key:String in obj ){
				var el:* = obj[key];
				if( typeof el === 'object' ){
					// If object has ref key, convert to reference
					if( Util.hasProp(el, 'ref') ){
						// Create reference
						var address:Array = el.ref ? (el.ref as Array).concat() : [];
						var operations:Array = el.operations ? (el.operations as Array).concat() : [];
						var ref:Reference = new Reference(bridge, address, operations);
						if(el.operations && el.operations.length === 1 && el.operations[0] === 'callback') {
							// Create callback wrapper
							obj[key] = Util.refCallback(ref);
						} else {
							obj[key] = ref;
						}
					} else {
						Serializer.unserialize(bridge, el);
					}
				}
			}	
			return obj;
		}
	}
}