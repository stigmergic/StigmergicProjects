package 
{
	import com.gestureworks.core.GestureWorks;
	import com.gestureworks.components.CMLDisplay; CMLDisplay;
	
	[SWF(width = "1024", height = "768", backgroundColor = "0x000000", frameRate = "60")]
	
	public class Main extends GestureWorks
	{
		public function Main():void 
		{
			super();
			settingsPath = "library/cml/my_application.cml";			
		}
		
	}
}

