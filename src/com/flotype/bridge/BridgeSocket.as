package com.flotype.bridge
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	[Event(name="onMessage", type="com.flotype.bridge.BridgeSocketEvent")]
	
	public class BridgeSocket extends Socket implements ISocket
	{
		
		private var _bridge:Bridge;

		public function get bridge():Bridge
		{
			return _bridge;
		}

		public function set bridge(value:Bridge):void
		{
			_bridge = value;
		}

		public function send(data:String):void {
			Util.info( 'bridgesocket send called: ' + data );
			var output:String = 'xxxx' + data;
			var bytes:ByteArray = new ByteArray();
			bytes.endian = Endian.BIG_ENDIAN;
			bytes.position = 0;
			bytes.writeUTFBytes(output);
			bytes.position = 0;
			bytes.writeUnsignedInt( bytes.length - 4 );
			Util.info( 'encoded message: ' + bytes.toString() );
			this.writeBytes(bytes);
			this.flush();
		}
		
		public function processQueue(sock:ISocket, clientId:String):void {
			// this does nothing here since we don't buffer at all
		}
		
		/**
		 * @inheritDoc 
		 */		
		public function BridgeSocket(host:String=null, port:int=0)
		{
			super(host, port);
		}
	}
}