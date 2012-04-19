package arduino
{
	public class DigitalPin
	{
		var pinNumber:Number;
		var value:Number;
		
		public function DigitalPin(pinNumber:Number)
		{
			this.pinNumber = pinNumber;
		}
		
		public function setValue(value:Number) {
			this.value = value;
		}
	}
}