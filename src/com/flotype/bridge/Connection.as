package com.flotype.bridge {
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.setTimeout;
	
	/**
	 * Represents a single connection to a Bridge server.
	 * 
	 * @author Ian Serlin
	 */	
	public class Connection {
		
		public function get clientId():String {
			return _clientId;
		}
		
		protected var _bridge:Bridge;
		protected var _options:Object;
		protected var _sockBuffer:SockBuffer;
		protected var _sock:ISocket;
		protected var _interval:int;
		protected var _clientId:String;
		protected var _secret:String;
		
		/**
		 * Constructor
		 * 
		 * @param bridge The Bridge instance that owns this connection instance
		 */		
		public function Connection(bridge:Bridge){
			this._bridge = bridge;
			this._options = bridge._options;
			this._sockBuffer = new SockBuffer();
			this._sock = _sockBuffer;
			this._interval = 400;
		}
		
		/**
		 * 
		 * 
		 */		
		public function redirector():void {
			var self:Connection = this;
			// Use JSON to retrieve host and port
			if( this._options.tcp ){
				var loader:URLLoader = new URLLoader();
				var request:URLRequest = new URLRequest(this._options.redirector + '/redirect/' + this._options.apiKey);
				loader.addEventListener(Event.COMPLETE, function(e:Event):void {
					try{
						var response:Object = JSON.decode( loader.data as String );
						self._options.host = response.data.bridge_host;
						self._options.port = response.data.bridge_port;
						if (!self._options.host || !self._options.port) {
							Util.error('Could not find host and port in JSON body');
						} else {
							self.establishConnection();
						}
					}catch(e:Error){
						Util.error('Unable to parse redirector response ' + loader.data);
					}
				});
				
				loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
					Util.error('Unable to contact redirector because of IO Error: '+ e.text );
				});
				
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent):void {
					Util.error('Unable to contact redirector because of Security Error: '+ e.text );
				});
				
				loader.load(request);
			}
		}
		
		protected function handleHandshake( e:BridgeSocketEvent ):void {
			var sock:BridgeSocket = e.target as BridgeSocket;
			var message:Object = e.value;
			var data:String = message.data as String,
				ids:Array = data.split('|');
			if (ids.length !== 2) {
				// Handle message normally if not a correct CONNECT response
				this.processMessage(e);
			} else {
				Util.info('clientId received', ids[0]);
				this._clientId = ids[0];
				this._secret = ids[1];
				this._interval = 400;
				// Send preconnect queued messages
				this._sock.processQueue(sock, this._clientId);
				// Set connection socket to connected socket
				this._sock = sock;
				// Set onmessage handler to handle standard messages
				this._sock.removeEventListener("onMessage", handleHandshake);
				this._sock.addEventListener("onMessage", processMessage);
				Util.info('Handshake complete');
				// Trigger ready callback
				if(!this._bridge._ready ){
					this._bridge._ready = true;
					this._bridge.emit('ready');
				}
			}
		}
		
		/**
		 * 
		 * 
		 */		
		public function establishConnection():void {
			var self:Connection = this;
			
			var sock:BridgeSocket;
			//var sock:ISocket;
			
			if (this._options.tcp) {
				Util.info('Starting TCP connection', this._options.host, this._options.port);
				sock = new TCP(this._options).sock;
				sock.bridge = this._bridge;
				sock.addEventListener(Event.CONNECT, function(e:Event):void {
					Util.info('Beginning handshake');
					var msg:String = Util.stringify({
						command: 'CONNECT'
						, data: {
							session: [ self.clientId || null, self._secret || null ]
							, api_key: self._options.apiKey
						}
					});
					sock.send(msg);
				});
				
				sock.addEventListener("onMessage", handleHandshake);
				sock.addEventListener(Event.CLOSE, onSocketClose);
			} 
		}
		
		public function reconnect():void {
			Util.info('Attempting reconnect');
			var self:Connection = this;
			if( this._interval < 32768 ){
				setTimeout(function():void {
					self.establishConnection();
					// Grow timeout for next reconnect attempt
					self._interval *= 2;
				}, this._interval);
			}
		}
		
		protected function onSocketClose(e:Event):void {
			Util.warn('Connection closed');
			// Restore preconnect buffer as socket connection
			this._sock = this._sockBuffer;
			if( this._options.reconnect ){
				this.reconnect();
			}
		}
		
		protected function processMessage(e:BridgeSocketEvent):void {
			var message:Object = e.value;
			try {
				Util.info('Received', message.data);
				message = Util.parse(message.data);
			} catch (e:Error) {
				Util.error('Message parsing failed');
				return;
			}
			// Convert serialized ref objects to callable references
			Serializer.unserialize(this._bridge, message);
			// Extract RPC destination address
			var destination:Object = message.destination;
			if (!destination) {
				Util.warn('No destination in message', message);
				return;
			}
			this._bridge.execute(message.destination._address, message.args);			
		}
		
		/**
		 * 
		 * @param command
		 * @param data
		 * 
		 */		
		public function sendCommand(command:String, data:Object):void {
			var msg:String = Util.stringify({command: command, data: data });
			Util.info('Sending', msg);
			this._sock.send(msg);
		}
		
		/**
		 * 
		 * 
		 */		
		public function start():void {
			if (!this._options.host || !this._options.port) {
				this.redirector();
			} else {
				// Host and port are specified
				this.establishConnection();
			}
		}
	}
}

import com.flotype.bridge.Bridge;
import com.flotype.bridge.ISocket;

import flash.events.EventDispatcher;

class SockBuffer extends EventDispatcher implements ISocket {
	protected var _buffer:Array = [];
	
	public function get bridge():Bridge {
		return null;
	}
	
	public function set bridge(value:Bridge):void {}
	
	public function send(msg:String):void {
		this._buffer.push(msg);
	}
	
	public function processQueue(sock:ISocket, clientId:String):void {
		for(var i:int = 0, ii:int = this._buffer.length; i < ii; i++) {
			// Replace null client ids with actual client_id after handshake
			sock.send(this._buffer[i].replace(/"client",null/g, '"client","'+clientId+'"'));
		}
		this._buffer = [];
	}
	
}