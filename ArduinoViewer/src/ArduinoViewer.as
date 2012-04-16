/** 
 * 
 *  April 13
 * 		Made the button creation/update/write/toggle into individual methods
 * 		Background color change on the button
 * 		Exception handling when lost connection with arduino -- Could be problem if arduino just loses power...
 * 		Reading the digital pin.  Unable to read analog so far. 
 *  April 16
 * 		Analog input is working
 * 		Re-worked how the data is read, now completely event based
 * 		Poteiometer (analog) reading is scaled between 0 and 1.0
 * 		Still need some work to get things going at the start (reset board required, sometimes twice)
 * 		
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 */

package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import net.eriksjodin.arduino.Arduino;
	import net.eriksjodin.arduino.events.ArduinoEvent;
	import net.eriksjodin.arduino.events.ArduinoSysExEvent;
	
	public class ArduinoViewer extends Sprite
	{
		private var arduino:Arduino;
		private var button:Sprite;
		private var buttonLabel:TextField;
		
		private var status:TextField;
		
		private var ledState:Boolean = false;
		
		private const firstDigitalPin:Number = 2;
		private const lastDigitalPin:Number = 53;

		private const firstAnalogPin:Number = 0;
		private const lastAnalogPin:Number = 5;//15;
		
		private var digitalPins:Array = new Array(lastDigitalPin+1);
		private var analogPins:Array = new Array(lastAnalogPin+1);
		
		public function ArduinoViewer()
		{
			initArduino();
			
			addChild(createButton());
			
			status = new TextField();
			status.text = "waiting... Press button to begin.";
			status.y = 100;
			status.height = 500;
			status.width = 500;
			
			status.background = true;
			status.backgroundColor = 0xCCCCCC;
			
			addChild(status);
		}

		protected function initArduino() {
			trace("starting connection...");
			try {
				arduino = new Arduino("127.0.0.1",5331);

				arduino.addEventListener(Event.CONNECT,onSocketConnect);
				arduino.addEventListener(Event.CLOSE,onSocketClose);
				arduino.addEventListener(ArduinoEvent.FIRMWARE_VERSION, firmwareHandler);
				arduino.addEventListener(ArduinoSysExEvent.SYSEX_MESSAGE, sysexHandler);
			
				writeButton();
			} catch (e:Error) {
				trace("Error: " + e);
				status.text = e.getStackTrace();
			}

		}

		private function setupArduino() {
			//arduino.setAnalogPinReporting(0, Arduino.INPUT);
			arduino.resetBoard();
			
			arduino.enableDigitalPinReporting();
			
			
			
			for (var i = firstDigitalPin; i<=lastDigitalPin; i++) {
				if (i == 13) continue; // LED is being used for output
				arduino.setPinMode(i, Arduino.INPUT);
				digitalPins[i] = 0;
			}

			for (var i = firstAnalogPin; i<=lastAnalogPin; i++) {
				arduino.setAnalogPinReporting(i, Arduino.ON);
				analogPins[i] = 0;
			}
			
			arduino.addEventListener(ArduinoEvent.ANALOG_DATA, analogHandler);
			arduino.addEventListener(ArduinoEvent.DIGITAL_DATA, digitalHandler);
		}
		
		private function onSocketConnect(e:Object):void {
			trace("Socket connected!");
			arduino.requestFirmwareVersion();
		}
		
		private function onSocketClose(e:Object):void {
			trace("Socket closed!");
		}
		
		protected function sysexHandler(event:ArduinoSysExEvent):void
		{
			trace(event);
			
			frameHandler(event);
		}
		
		protected function firmwareHandler(event:ArduinoEvent):void
		{
			trace(event);
			
			setupArduino();
			
			frameHandler(event);
		}
		
		protected function digitalHandler(event:ArduinoEvent):void
		{
			var pin:Number = event.pin;
			var value:Number = event.value;

			digitalPins[pin] = value;
			
			//trace("Digital Pin: " + pin + " val: " + value);
			
			frameHandler(event);
		}
		
		protected function analogHandler(event:ArduinoEvent):void
		{
			var pin:Number = event.pin;
			var value:Number = event.value;
			
			analogPins[pin] = value/1023.0;

			//trace("Analog Pin: " + pin + " val: " + value);
			
			frameHandler(event);
		}

		
		private function updateButton():void {
			buttonLabel.text = ledState?"ON":"OFF";		
			buttonLabel.textColor = 0xFFFFFF;
			
			buttonLabel.background = true;
			buttonLabel.backgroundColor = ledState?0x00CF0F:0xFF0F00;
		}
		
		private function writeButton():void {
			try {
				arduino.setPinMode(13, Arduino.OUTPUT);
				arduino.writeDigitalPin(13, ledState?Arduino.HIGH:Arduino.LOW);				
			} catch (e:Error) {
				trace('Error: ' + e + "\ntype: " + e.errorID + " " );
				
				initArduino();
				
				//possible endless loop here. writeButton is called from initArduino... 
			
			}
			
		}
		
		private function createButton():Sprite {
			button = new Sprite();
			buttonLabel = new TextField();
			
			updateButton();
			button.addChild(buttonLabel);
			
			
			button.addEventListener(MouseEvent.CLICK, toggleHandler);
			return button;
		}
		
		private function toggleButton():void {
			ledState = !ledState;
			
			writeButton();
			updateButton();		
		}
		
		private function toggleHandler(event:Event):void {
			toggleButton();

			trace("Button: " + buttonLabel.text);			
		}


		private function digitalPinState():String {
			var status:String = "";
			
			for (var i:int=0; i<=lastDigitalPin; i++) {
				if ((i<firstDigitalPin) || (i == 13)) {
					status += 'L';
					continue; // LED is being used for output
				}
				
				try {
					//status += arduino.getDigitalData(i).toString();
					status += digitalPins[i].toString();
				} catch (e:Error) {
					status += '@';
				}
				status += ((i+1) % 10 == 0) ? "\n" : "";
			}
			status += '\n';
			
			return status;
		}
		
		private function analogPinState():String {
			var status:String = "";
			for (var i:int=firstAnalogPin; i <= lastAnalogPin; i++) {
				try {
					//status += arduino.getAnalogData(i).toString() + " ";
					status += numberFormat(analogPins[i], 3, true) + " ";
				} catch (e:Error) {
					status += '@\n' ;
				}				
				status += ( ((i+1) % 5 == 0) ? "\n" : "" );
			}
			
			return status;
		}
		
		private function pinState():String {
			var status:String = digitalPinState();
			status += analogPinState();
			return status;
		}
		
		private function frameHandler(event:Event):void {
			writeButton();
			updateButton();
												
			status.text = "";
			status.appendText( "Firmware: " + arduino.getFirmwareVersion() + "\n");
			status.text += "connected: " + arduino.connected + "\n";
			status.text +=  pinState();
			
			//trace(status.text);			
		}
		
		function numberFormat(number:*, maxDecimals:int = 2, forceDecimals:Boolean = false, siStyle:Boolean = false):String {
			//This method from: http://snipplr.com/view.php?codeview&id=27081
			var i:int = 0;
			var inc:Number = Math.pow(10, maxDecimals);
			var str:String = String(Math.round(inc * Number(number))/inc);
			    	var hasSep:Boolean = str.indexOf(".") == -1, sep:int = hasSep ? str.length : str.indexOf(".");
			    	var ret:String = (hasSep && !forceDecimals ? "" : (siStyle ? "," : ".")) + str.substr(sep+1);
			    	if (forceDecimals) {
				for (var j:int = 0; j <= maxDecimals - (str.length - (hasSep ? sep-1 : sep)); j++) ret += "0";
			}
			    	while (i + 3 < (str.substr(0, 1) == "-" ? sep-1 : sep)) ret = (siStyle ? "." : ",") + str.substr(sep - (i += 3), 3) + ret;
			    	return str.substr(0, sep - i) + ret;
		}
	}
	
}