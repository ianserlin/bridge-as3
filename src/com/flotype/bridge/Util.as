package com.flotype.bridge
{
	import com.adobe.serialization.json.JSON;

	/**
	 * A set of static utility methods used internally by
	 * the Bridge client. 
	 * 
	 * @author Ian Serlin
	 */	
	public class Util {
		
		/**
		 * The logging function you want calls to Util.log/info/warn/error to use. 
		 * 
		 * @default trace
		 */		
		public static var log:Function = trace;
		
		/**
		 * The logging cut-off level.
		 * 
		 * Currently:
		 * 0 = no logging
		 * 1 = errors only
		 * 2 = errors and warnings
		 * 3 = errors, warnings and info
		 * 
		 * @default Positive Infinity
		 */		
		public static var logLevel:Number = Number.MAX_VALUE
		
		/**
		 * The parser function Util provides.
		 * 
		 * @default JSON.decode 
		 */		
		public static var parse:Function = JSON.decode;
		
		/**
		 * The stringify function Util provides.
		 * 
		 * @default JSON.encode 
		 */		
		public static var stringify:Function = JSON.encode;
			
		/**
		 * Returns true if given object is the direct
		 * owner of the specified property.
		 *  
		 * @param obj The object you want to test the existence of prop on.
		 * @param prop The name of the property you want to test the existence of.
		 * 
		 * @return true if the object owns the specified property, false otherwise 
		 */		
		public static function hasProp(obj:Object, prop:String):Boolean {
			return obj.hasOwnProperty(prop);
		}
		
		/**
		 * Doesn't actually 'extend' the parent, simply copies
		 * property values from the parent to the child.
		 * 
		 * @param child
		 * @param parent
		 * 
		 * @return the extended child object
		 */		
		public static function extend(child:Object, parent:Object):Object {
			if( child && parent ){
				for( var key:String in parent ){
					if( hasProp( parent, key ) ){
						child[key] = parent[key];
					}
				}
			}
			// from JS, not sure why we need this
			// function ctor() { this.constructor = child; }
			// ctor.prototype = parent.prototype;
			// child.prototype = new ctor;
			// child.__super__ = parent.prototype;
			
			return child;
		}
		
		/**
		 * Generates a 12 character pseudo-random GUID.
		 * 
		 * @return the genrated pseudo-random GUID
		 */		
		public static function generateGuid():String {
			var text:String = "";
			var possible:String = "abcdefghijklmnopqrstuvwxyz0123456789";
			for( var i:int = 0; i < 12; i++ )
				text += possible.charAt(Math.floor(Math.random() * possible.length));
			return text;
		}
		
		/**
		 * Returns the proper type of the given value,
		 * can distinguish between arrays and objects.
		 * 
		 * @param value the value you want to know the type of
		 * @return the type of the given value as a String
		 */		
		public static function typeOf(value:*):String {
			var s:String = typeof value;
			if (s === 'object') {
				if (value) {
					if (typeof value.length === 'number' &&
						!(value.propertyIsEnumerable('length')) &&
						typeof value.splice === 'function') {
						s = 'array';
					}
				} else {
					s = 'null';
				}
			}
			return s;
		}
		
		/**
		 * Inspects the given object and creates an array
		 * of Strings representing the immediate methods
		 * of the object.
		 * 
		 * @param obj the object you want to know the method names of
		 * @return an array of Strings representing the methods on the object
		 */		
		public static function findOps(obj:Object):Array {
			var result:Array = [];
			for (var key:String in obj) {
				if (typeof(obj[key]) === 'function' && isValid(key)) {
					result.push(key);
				}
			}
			return result;
		}
		
		/**
		 * Returns true if the given name is a valid Bridge
		 * method or property identifier, false otherwise.
		 *  
		 * @param name the name you want to check the validity of
		 * @return true if the given name is a valid, false otherwise
		 * 
		 */		
		public static function isValid(name:String):Boolean {
			// Ignore private methods
			return name.charAt(0) !== '_';
		}
		
		// Not implemented from JS
//		inherit: function (ctor, ctor2) {
//			var f = function () {};
//			f.prototype = ctor2.prototype;
//			ctor.prototype = new f;
//		}
		
		public static function info(...args):void {
			if( log != null && logLevel >= 3 ){
				log.apply( Util, args );
			}
		}
		
		public static function warn(...args):void {
			if( log != null && logLevel >= 2 ){
				log.apply( Util, args );
			}
		}
		
		public static function error(...args):void {
			if( log != null && logLevel >= 1 ){
				log.apply( Util, args );
			}
		}
		
		public static function refCallback(reference:Reference):Object {
			var wrapper:Object = {
				_reference: reference,
				_toDict: function():Object{
					return reference._toDict();
				},
				callback: function(...args):* {
					return reference._call('callback', args);
				}
			};
			return function(...args):* {
				return wrapper.callback.apply(wrapper,args);
			}
		}
		
	}
	
//	/**
//	 * Class used by Util.refCallback
//	 * 
//	 * @author Ian Serlin
//	 */	
//	public class ReferenceCallback {
//		public var _toDict:Function;
//		public var callback:Function;
//		
//		protected var _args:Array;
//		protected var _ref:Reference;
//		protected var _execute:Function;
//		
//		public function ReferenceCallback(ref:Reference) {
//			_args = args;
//			_ref = ref;
//			_toDict = function():* {
//				return _ref._toDict();
//			};
//			_execute = function(...rest):* {
//				_ref._call('callback', rest);
//			};
//			callback = _execute;
//		}
//	}
}