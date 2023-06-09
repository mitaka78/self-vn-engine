package engine;

import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.animation.FlxAnimation;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.Json;
import lime.utils.Assets;
import engine.dialogue.DialogueParser;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import engine.dialogue.DialogueBox;
import flixel.addons.transition.TransitionData;
import flixel.math.FlxRect;
import flixel.addons.transition.FlxTransitionableState;

typedef SceneFile = {
	var levelInfo:{chapter:String, scene:String};
	var initialBackground:{x:Float, y:Float, image:String};
	var initialBGM:{song:String, volume:Float, ?looped:Bool, ?fadeInDuration:Float, ?fadeOutDuration:Float};
	var initialDialogue:String;
	var transIn:{type: TransitionType, duration: Float, color: Int};
	var transOut:{type: TransitionType, duration: Float, color: Int};
	var spritePresets:Array<Preset>;
}

typedef Preset = {
	var name:String;
	var image:String;
	var width:Float;
	var height:Float;
	var anims:Array<{name:String, framerate:Int, frames:Array<Int>, ?looped:Bool}>;
}

class Scene extends FlxTransitionableState
{

	public var sceneFile:SceneFile;

	public var background:FlxSprite;
	public var backgroundSprites:FlxTypedGroup<FlxSprite>;
	public var foregroundSprites:FlxTypedGroup<FlxSprite>;
	public var UI:FlxTypedGroup<FlxSprite>;

	public var UIcam:FlxCamera;

	public var dialogue:Array<Action>;
	public var dialogueBox:DialogueBox;

	public var spritePresets:Map<String, Preset> = [];

	public function new(sceneFilePath:String)
	{
		super();
		#if debug
		Debug.log("Initializing scene", "scene");
		#end

		sceneFile = cast Json.parse(Assets.getText(sceneFilePath));
		transIn = new TransitionData(sceneFile.transIn.type, sceneFile.transIn.color, sceneFile.transIn.duration);
		transOut = new TransitionData(sceneFile.transIn.type, sceneFile.transIn.color, sceneFile.transIn.duration);
		dialogue = DialogueParser.parse(Assets.getText(sceneFile.initialDialogue));

		if (sceneFile.spritePresets != null) {
			for (i in sceneFile.spritePresets) {
				spritePresets.set(i.name, i);
			}
		}
	}

	public override function create() {

		Save.bind("Save_1");
		Controls.init();

		backgroundSprites = new FlxTypedGroup<FlxSprite>();
		foregroundSprites = new FlxTypedGroup<FlxSprite>();
		UI = new FlxTypedGroup<FlxSprite>();


		UIcam = new FlxCamera();
		UIcam.scroll.set();
		UIcam.bgColor= FlxColor.TRANSPARENT;

		FlxG.cameras.add(UIcam);

		UI.memberAdded.add(function(s) {
			s.scrollFactor.set();
			s.cameras = [UIcam];
			s.camera = s.cameras[0];
		});

		add(backgroundSprites);
		add(foregroundSprites);
		add(UI);


		background = new FlxSprite(sceneFile.initialBackground.x, sceneFile.initialBackground.y);
		
		if (sceneFile.initialBackground.image != null && sceneFile.initialBackground.image.length > 0)
			background.loadGraphic(sceneFile.initialBackground.image);	

		backgroundSprites.add(background);

		if (sceneFile.initialBGM != null && sceneFile.initialBGM.song != null && sceneFile.initialBGM.song.length > 0) {
			FlxG.sound.playMusic(sceneFile.initialBGM.song);
			FlxG.sound.music.fadeIn(sceneFile.initialBGM.fadeInDuration, 0, sceneFile.initialBGM.volume);
		}
		dialogueBox = new DialogueBox(60, 420, dialogue, this);
		dialogueBox.currentFadeOutDuration = sceneFile.initialBGM.fadeOutDuration;

		UI.add(dialogueBox);

		#if debug
		Debug.log("Scene fully loaded.", "scene");
		#end

		super.create();
	}

	public override function update(elapsed:Float) {
		#if debug
		if (FlxG.keys.justPressed.R)
			FlxG.switchState(new Scene("assets/level.json"));
		#end
		super.update(elapsed);
	}
}
