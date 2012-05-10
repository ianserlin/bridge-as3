package com.flotype.bridge {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	[Event(name="onConnect", type="flash.events.Event")]
	
	/**
	 * TCP Socket abstraction layer for Bridge.
	 * 
	 * @author Ian Serlin
	 */
	public class TCP extends EventDispatcher {
		
		public var callback:Function;
		
		public function get sock():BridgeSocket {
			return _socket;
		}
		
		protected var _socket:BridgeSocket;
		protected var _buffer:ByteArray;
		protected var _options:Object;
		
		/**
		 * Constructor
		 * 
		 * @param options 
		 * 
		 */		
		public function TCP(options:Object) {
			_socket = new BridgeSocket();
			_socket.addEventListener(Event.CLOSE, onClose);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onChunk);
			_socket.addEventListener(Event.CONNECT, onConnect);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			
			_options = options;

			_socket.connect(options.host, options.port);
		}
		
		protected function onConnect(e:Event):void {
			Util.info('TCP Socket on connect. Host: ' + _options.host + ' port: ' + _options.port);
			dispatchEvent( new Event( 'onConnect' ) );
		}
		
		protected function onClose(e:Event):void {
			// Security error is thrown if this line is excluded
			Util.info( 'onclose called' );
			_socket.close();
		}
		
		protected function onError(e:IOErrorEvent):void {
			Util.error( 'TCP Socket IOError: (' + e.errorID + ')' + e.text );
		}
		
		protected function onSecurityError(e:SecurityErrorEvent):void {
			Util.error( 'TCP Socket SecurityError: (' + e.errorID + ')' + e.text );
		}
		
		protected var _messageLength:Number = -1;
		protected var _bytesLeftToRead:Number = -1;
		
		protected function readHeaderBytes():void {
			Util.info( 'attempting to read header bytes, available bytes: ' + _socket.bytesAvailable );
			if( _socket.bytesAvailable >= 4 ){
				_messageLength = _socket.readUnsignedInt();
				_bytesLeftToRead = _messageLength;
				readBytes();
			}
		}
		
		protected function readBytes():void {
			if( _socket.bytesAvailable > 0 ){
				// 1. read header bytes
				if( _messageLength < 0 ){
					readHeaderBytes();
				}else{
					if( _buffer == null ){
						_buffer = new ByteArray();
					}
					if( _socket.bytesAvailable >= _bytesLeftToRead ){
						Util.info( 'all message bytes are available: ' + _socket.bytesAvailable );
						
						// 2a. read message bytes
						_socket.readBytes(_buffer, _buffer.position, _bytesLeftToRead);
						// 3. trigger callback
						_socket.dispatchEvent( new BridgeSocketEvent( BridgeSocketEvent.ON_MESSAGE, { data: _buffer.readUTFBytes(_buffer.length) } ) );
						// 4. reset buffer and wait for more header bytes
						_messageLength = _bytesLeftToRead = -1;
						_buffer = null;
						readHeaderBytes();
					}else{
						Util.info( 'NOT all message bytes are available: ' + _socket.bytesAvailable );
						// 2b. haven't received all bytes in the message yet
						var bytesRead:int = _socket.bytesAvailable;
						_socket.readBytes(_buffer, _buffer.position, _socket.bytesAvailable);
						_bytesLeftToRead -= bytesRead;
					}
				}
			}
		}
		
		protected function onChunk(e:ProgressEvent):void {
			readBytes();			
			
//			var message:String = "";
//			while(_socket.bytesAvailable){
//				message += _socket.readUTF();
//			}
//			trace( "Received: " + message);
//			_socket.dispatchEvent( new BridgeSocketEvent( BridgeSocketEvent.ON_MESSAGE, { data: message } ) );
		}
	}
}