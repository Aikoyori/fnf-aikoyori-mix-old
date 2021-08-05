package;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var char:String = 'bf';
	public var isPlayer:Bool = false;
	public var isOldIcon:Bool = false;

	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public function new(?char:String = "bf", ?isPlayer:Bool = false)
	{
		super();
		
		loadGraphic(Paths.image('iconGrid'), true, 150, 150);

		antialiasing = true;
		animation.add('bf', [0 ,0, 1], 0, false, isPlayer);
		animation.add('bf-car', [0, 0, 1], 0, false, isPlayer);
		animation.add('bf-christmas', [0, 0, 1], 0, false, isPlayer);
		animation.add('bf-pixel', [21, 22, 23], 0, false, isPlayer);
		animation.add('spooky', [2,2, 3], 0, false, isPlayer);
		animation.add('pico', [4,4, 5], 0, false, isPlayer);
		animation.add('mom', [6,6, 7], 0, false, isPlayer);
		animation.add('mom-car', [6,6, 7], 0, false, isPlayer);
		animation.add('tankman', [8,8, 9], 0, false, isPlayer);
		animation.add('face', [10,10, 11], 0, false, isPlayer);
		animation.add('dad', [12, 12, 13], 0, false, isPlayer);
		animation.add('senpai', [24,25, 26], 0, false, isPlayer);
		animation.add('senpai-angry', [27,28,29], 0, false, isPlayer);
		animation.add('spirit', [36,36,36], 0, false, isPlayer);
		animation.add('bf-old', [14,14, 15], 0, false, isPlayer);
		animation.add('gf', [16,16,16], 0, false, isPlayer);
		animation.add('gf-christmas', [16,16,16], 0, false, isPlayer);
		animation.add('gf-pixel', [16,16,16], 0, false, isPlayer);
		animation.add('parents-christmas', [17,17, 18], 0, false, isPlayer);
		animation.add('monster', [19,19, 20], 0, false, isPlayer);
		animation.add('monster-christmas', [19,19, 20], 0, false, isPlayer);
		animation.add('sunflower', [30,30,31], 0, false, isPlayer);
		animation.add('zomboss', [32,32,33], 0, false, isPlayer);
		animation.add('wallnut', [34,34,35], 0, false, isPlayer);
		animation.play(char);

		this.char = char;
		this.isPlayer = isPlayer;

		isPlayer = isOldIcon = false;

		if (FlxG.save.data.antialiasing)
		{
			switch(char)
			{
				case 'bf-pixel' | 'senpai' | 'senpai-angry' | 'spirit' | 'gf-pixel':
					antialiasing = false;
				default:
					antialiasing = true;
			}
		}

		changeIcon(char);
		scrollFactor.set();
	}

	public function swapOldIcon()
	{
		(isOldIcon = !isOldIcon) ? changeIcon("bf-old") : changeIcon(char);
	}

	public function changeIcon(char:String)
		{
			/*if (char != 'bf-pixel' && char != 'bf-old')
				char = char.split("-")[0];*/
			animation.play(char);
		}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
