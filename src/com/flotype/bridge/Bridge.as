package com.flotype.bridge
{
	import flash.system.Security;
	import flash.utils.Dictionary;

	/**
	 * The Bridge client and associated API. 
	 * 
	 * @author Ian Serlin
	 */	
	public class Bridge
	{
		// --------------- Static Properties -----------------
		
		/**
		 * Set of default Bridge configuration options. 
		 */		
		private static const defaultOptions:Object = {
			redirector: 'http://redirector.flotype.com',
			reconnect: true,
			log: 4,
//			log: 2,
			tcp: true
		};
		
		// --------------- Public Properties -----------------
		
		// --------------- Protected Properties -----------------
		
		/**
		 * @private
		 * 
		 * Configuration options for this Bridge instance. 
		 */		
		internal var _options:Object = {};
		
		/**
		 * Manages references to local and remote object, functions, etc. 
		 */		
		protected var _store:Dictionary = new Dictionary(true);
		
		/**
		 * Indicates whether the server is connected and handshaken. 
		 */		
		internal var _ready:Boolean = false;
		
		/**
		 * The Connection object associated with this instance of Bridge. 
		 */		
		protected var _connection:Connection;
		
		/**
		 * Manages references to our event handlers. 
		 */		
		protected var _events:Object = {};
		
		// --------------- Constructor -----------------
		
		/**
		 * Constructor
		 *  
		 * @param options
		 * 
		 */		
		public function Bridge(options:Object) {
			var self:Bridge = this;
			
			// Initialize system call service
			var system:Object = {
				hookChannelHandler: function(name:String, handler:Object, callback:Function):void {
					// Retrieve requested handler
					var obj:Object = self._store[handler._address[2]];
					// Store under channel name
					self._store['channel:' + name] = obj;
					if( callback != null ){
						// Send callback with reference to channel and handler operations
						var ref:Reference = new Reference(self, ['channel', name, 'channel:' + name], Util.findOps(obj));
						callback(ref, name);
					}
				},
				getService: function(name:String, callback:Function):void{
					if (Util.hasProp(self._store, name)) {
						callback(self._store[name], name);
					} else {
						callback(null, name);
					}
				},
				remoteError: function(msg:String):void {
					Util.warn(msg);
					self.emit('remoteError', [msg]);
				}
			};
			
			this._options = Util.extend(defaultOptions, options);
			
			Util.logLevel = this._options.log;
			
			// Initialize system call service
			this._store['system'] = system;
			
			// Indicates whether server is connected and handshaken
			this._ready = false;
			
			// Create connection object
			this._connection = new Connection(this);
			
			// Store event handlers
			this._events = {};
			
			// TODO: is this necessary?
			Security.allowDomain('*');
		}
		
		// --------------- Public Methods -----------------
		
		/**
		 * Adds an event handler to this Bridge instance.
		 *  
		 * @param name The name of the event you want to listen for.
		 * @param callback The function you want executed when the event occurs.
		 * 
		 * @return the Bridge instance 
		 */		
		public function on(name:String, callback:Function):Bridge {
			if( !Util.hasProp( this._events, name ) ){
				this._events[name] = [];
			}
			this._events[name].push(callback);
			return this;
		}
		
		/**
		 * Emits an event
		 * 
		 * @param name the name of the event you want to emit
		 * @param args the arguments you want passed to the event handlers
		 * 
		 * @return the Bridge instance 
		 */		
		public function emit(name:String, args:Array=null):Bridge {
			if( Util.hasProp( this._events, name ) ){
				var events:Array = this._events[name].slice(0);
				for (var i:int = 0, ii:int = events.length; i < ii; i++) {
					(events[i] as Function).apply(this, args === null ? [] : args);
				}
			}
			return this;
		}
		
		/**
		 * Removes an event handler.
		 * 
		 * @param name The name of the event you want to remove a callback from
		 * @param callback The callback you want to stop listening to the given event
		 * 
		 * @return the Bridge instance 
		 */		
		public function removeEvent(name:String, callback:Function):Bridge {
			if( Util.hasProp(this._events, name) ){
				for( var i:int = 0, l:int = this._events[name].length; i < l; i++) {
					if (this._events[name][i] === callback) {
						this._events[name].splice(i, 1);
					}
				}
			}
			return this;
		}
		
		/**
		 * Calls the given callback when Bridge is connected and ready.
		 * Calls the given callback immediately if Bridge is already ready.
		 * Not called on reconnection.
		 *  
		 * @param callback Called when Bridge is connected and ready for use.
		 */		
		public function ready(callback:Function):void {
			if( !this._ready ){
				this.on( 'ready', callback );
			}else{
				callback();
			}
		}
		
		/**
		 * Starts the conenction to the Bridge server.
		 * 
		 * If a callback is given, calls the given callback
		 * when Bridge is connected and ready.
		 * 
		 * @param callback Called when Bridge is connected and ready for use.
		 * 
		 * @return the Bridge instance
		 */		
		public function connect(callback:Function=null):Bridge {
			if( callback != null ){
				this.ready( callback );	
			}
			this._connection.start();
			return this;
		}
		
		/**
		 * 
		 * @param name
		 * @param handler
		 * @param callback
		 * 
		 */		
		public function publishService(name:String, handler:Object, callback:Function=null):void {
			if( name === 'system' ){
				Util.error('Invalid service name', name);
			} else {
				this._store[name] = handler;
				this._connection.sendCommand('JOINWORKERPOOL', {name: name, callback: Serializer.serialize(this, callback)});
			}
		}
		
		/**
		 * 
		 * @param name
		 * @param callback
		 * @param 
		 * 
		 */		
		public function unpublishService(name:String, callback:Function):void {
			if (name === 'system') {
				Util.error('Invalid service name', name);
			} else {
				this._connection.sendCommand('LEAVEWORKERPOOL', {name: name, callback: Serializer.serialize(this, callback)});
			}
		}
		
		/**
		 * 
		 * @param name
		 * @param callback
		 * 
		 */										 
		public function getService(name:String, callback:Function):void {
			this._connection.sendCommand('GETOPS', {name: name, callback: Serializer.serialize(this, callback)});
		}
		
		/**
		 * 
		 * @param name
		 * @param callback
		 * 
		 */		
		public function getChannel(name:String, callback:Function):void {
			var self:Bridge = this;
			this._connection.sendCommand('GETCHANNEL', {name: name, callback: Serializer.serialize(this, function(service:Object, name:String):void {
				name = name.split(':')[1];
				if (service === null) {
					callback(null, name);
					return;
				}
				// Callback with channel reference merged with operations from GETCHANNEL
				callback(new Reference(self, ['channel', name, 'channel:' + name], service._operations), name);
			})});
		}
		
		/**
		 * 
		 * @param name
		 * @param handler
		 * @param callback
		 * 
		 */		
		public function joinChannel(name:String, handler:Object, callback:Function):void {
			this._connection.sendCommand('JOINCHANNEL', {name: name, handler: Serializer.serialize(this, handler), callback: Serializer.serialize(this, callback)});
		}
		
		public function leaveChannel(name:String, handler:Object, callback:Function):void {
			this._connection.sendCommand('LEAVECHANNEL', {name: name, handler: Serializer.serialize(this, handler), callback: Serializer.serialize(this, callback)});
		}
		
		// --------------- Protected Methods -----------------
		
		/**
		 * @private
		 * 
		 * Stores a handler on this Bridge instance.
		 *  
		 * @param handler The handler being stored
		 * @param ops The array of string names representing operations this handler supports
		 * 
		 */		
		internal function _storeObject(handler:Object, ops:Array):Reference {
			// Generate random id for callback being stored
			var name:String = Util.generateGuid();
			this._store[name] = handler;
			// Return reference to stored callback
			return new Reference( this, ['client', this._connection.clientId, name], ops );
		}
		
		/**
		 * Executes a local or remote Bridge managed method.
		 * 
		 * @param address Address of the method to execute
		 * @param args Arguments to pass to the method
		 */		
		internal function execute(address:Array, args:Object ):void {
			// Retrieve stored handler
			var obj:Object = this._store[address[2]];
			// Retrieve function in handler
			var func:Function = obj[address[3]];
			if( func != null ){
				try {
					func.apply( obj, args );
				} catch (err:Error) {
					Util.error(err.name + ' ' + err.errorID + ' ' + err.message );
					Util.error('Exception while calling ' + address[3] + '(' + args.toString() + ')');
				}
			} else {
				// TODO: Throw exception
				Util.warn('Could not find object to handle', address);
			}
		}
		
		/**
		 * Sends a command to the Bridge server.
		 * 
		 * @param args The arguments you want to send
		 * @param destination Bridge address you want to send the arguments to
		 */		
		internal function send(args:Array, destination:Object ):void {
			this._connection.sendCommand('SEND', { 'args': Serializer.serialize(this, args), 'destination': destination});
		}
	}
}