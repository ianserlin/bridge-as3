package com.flotype.bridge
{
	import flash.events.IEventDispatcher;

	public interface ISocket extends IEventDispatcher
	{
		function send(message:String):void;
		function get bridge():Bridge;
		function set bridge( value:Bridge ):void;
		function processQueue(sock:ISocket, clientId:String):void;
	}
}