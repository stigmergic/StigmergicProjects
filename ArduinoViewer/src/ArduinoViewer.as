/** 
 * 
 *  April 13
 * 		Made the button creation/update/write/toggle into individual methods
 * 		Background color change on the button
 * 		Exception handling when lost connection with arduino -- Could be problem if arduino just loses power...
 * 		Reading the digital pin.  Unable to read analog so far. 
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
		
		private var firstDigitalPin:Number = 2;
		private var lastDigitalPin:Number = 53;

		private var firstAnalogPin:Number = 0;
		private var lastAnalogPin:Number = 15;
		
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
				arduino = new Arduino();
					
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
			}

			for (var i = firstAnalogPin; i<=lastAnalogPin; i++) {
				arduino.setAnalogPinReporting(i, Arduino.INPUT);
			}
			
			arduino.addEventListener(ArduinoEvent.ANALOG_DATA, analogHandler);
			arduino.addEventListener(ArduinoEvent.DIGITAL_DATA, digitalHandler);
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
			trace(event);
			
			frameHandler(event);
		}
		
		protected function analogHandler(event:ArduinoEvent):void
		{
			trace(event);
			
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


		private function pinState():void {
			
		}
		
		private function frameHandler(event:Event):void {
			writeButton();
			updateButton();
						
			
			status.text =  "";
			//status.text += "connected: " + arduino.connected + "\n";
			status.appendText( "Firmware: " + arduino.getFirmwareVersion() + "\n");
			//status.appendText("Pin A0: " + arduino.getAnalogData(0) + "\n");

			for (var i=0; i<=lastDigitalPin; i++) {
				if ((i<firstDigitalPin) || (i == 13)) {
					status.text += 'L';
					continue; // LED is being used for output
				}
				
				try {
					//status.text += arduino.getDigitalData(i) ? 'X':'O';
					//arduino.setPinMode(i, Arduino.INPUT);
					status.appendText(arduino.getDigitalData(i).toString());
				} catch (e:Error) {
					status.appendText( '@' );
				}
				status.appendText( ((i+1) % 10 == 0) ? "\n" : "" );
			}
			
			for (var i=firstAnalogPin; i <= lastAnalogPin; i++) {
				try {
					//status.text += arduino.getDigitalData(i) ? 'X':'O';
					//arduino.setPinMode(i, Arduino.INPUT);
					status.appendText(arduino.getAnalogData(i).toString() + "\n");
				} catch (e:Error) {
					status.appendText( '@\n' );
				}				
			}

			
			trace(status.text);			
		}
	}
	
}