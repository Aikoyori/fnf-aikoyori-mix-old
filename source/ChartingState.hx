package;

import flixel.input.keyboard.FlxKey;
import flixel.FlxCamera;
import flixel.addons.ui.FlxUIText;
import haxe.zip.Writer;
import Conductor.BPMChangeEvent;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

class ChartingState extends MusicBeatState
{
	var _file:FileReference;

	public static var instance:ChartingState;
	public var playClaps:Bool = false;

	public var snap:Int = 1;

	var UI_box:FlxUITabMenu;
    
	var UI_options:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dad Battle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;
	var writingNotesText:FlxText;
	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var currentNoteType:String = "normal";

	var gridBG:FlxSprite;

	var _song:SwagSong;

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;

	var tempBpm:Float = 0;
	var gridBlackLine:FlxSprite;
	var vocals:FlxSound;

	var defaultSnap:Bool = true;

	var player2:Character = new Character(0,0, "dad");
	var player1:Boyfriend = new Boyfriend(0,0, "bf");

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	private var lastNote:Note;
	var claps:Array<Note> = [];

	public var beatsShown:Float = 1; // for the zoom factor
	public var zoomFactor:Float = 1;

	public var sectionRenderes:FlxTypedGroup<SectionRender>;
	public var snapText:FlxText;
	
	public var chartEvents:Array<Song.Event> = [];

	public var Typeables:Array<FlxUIInputText> = [];

	public static var latestChartVersion = "2";

	public var lines:FlxTypedGroup<FlxSprite>;
    
	public var texts:FlxTypedGroup<FlxText>;
    
	public var deezNuts:Map<Int,Int> = new Map<Int,Int>();
    
	override function create()
	{
		curSection = lastSection;
		FlxG.mouse.visible = true;

		FlxG.sound.muteKeys = null;

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = {
				chartVersion: latestChartVersion,
				song: 'Test',
				notes: [],
				eventObjects: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				noteStyle: 'normal',
				stage: 'stage',
				gimmick: 'none',
				loopAtStep: 0,
				loopToStep: 0,
				speed: 1,
				doesLoop: false,
				isBossFight: false,
				opponentHealth: 2,
				startingHealth: 1,
				validScore: false,
				healthLossModifier: 1.0,
				healthGainModifier: 1.0
			};
		}

		instance = this;

		deezNuts.set(4,1);
		deezNuts.set(8,2);
		deezNuts.set(16,4);
		deezNuts.set(32,8);
		deezNuts.set(64,16);

		sectionRenderes = new FlxTypedGroup<SectionRender>();
		lines = new FlxTypedGroup<FlxSprite>();
		texts = new FlxTypedGroup<FlxText>();
		
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		var blackBorder:FlxSprite = new FlxSprite(60,10).makeGraphic(120,100,FlxColor.BLACK);
		blackBorder.scrollFactor.set();

		blackBorder.alpha = 0.3;

		snapText = new FlxText(60,10,0,"Snap: 1/" + snap + " (Press Control to unsnap the cursor)\nAdd Notes: 1-8 (or click)\n", 14);
		snapText.scrollFactor.set();

		gridBlackLine = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		leftIcon = new HealthIcon(_song.player1);
		rightIcon = new HealthIcon(_song.player2);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);
		leftIcon.animation.curAnim.curFrame = 1;
		rightIcon.animation.curAnim.curFrame = 1;
		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song Data'},
			{name: "Section", label: 'Section Data'},
			{name: "Note", label: 'Note Data'},
			{name: "Assets", label: 'Assets'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;

		var opt_tabs = [{name: "Options", label:'Song Options'}, {name: "Events", label:'Song Events'}];
        

		UI_options = new FlxUITabMenu(null, opt_tabs, true);

		UI_options.scrollFactor.set();
		UI_options.selected_tab = 0;
		UI_options.resize(300, 200);
		UI_options.x = UI_box.x;
		UI_options.y = FlxG.height - 300;
		add(UI_options);
		
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();
        addEventsUI();
        addOptionsUI();

		add(curRenderedNotes);
		add(curRenderedSustains);

		add(blackBorder);
		add(snapText);


		if (_song.eventObjects == null)
			_song.eventObjects = [new Song.Event("Init BPM",0,_song.bpm,"BPM Change")];

		if (_song.eventObjects.length == 0)
			_song.eventObjects = [new Song.Event("Init BPM",0,_song.bpm,"BPM Change")];
		
        regenerateLines();
		updateHeads();
		super.create();
	}

	function containsName(name:String, events:Array<Song.Event>):Song.Event
        {
            for (i in events)
            {
                var thisName = Reflect.field(i,"name");
    
                if (thisName == name)
                    return i;
            }
            return null;
        }
	function addEventsUI()
	{
			if (_song.eventObjects == null)
			{
				_song.eventObjects = [new Song.Event("Init BPM",0,_song.bpm,"BPM Change")];
			}
	
			var firstEvent = "";
	
			if (Lambda.count(_song.eventObjects) != 0)
			{
				firstEvent = _song.eventObjects[0].name;
			}
	
			var listLabel = new FlxText(10, 5, 'List of Events');
			var nameLabel = new FlxText(150, 5, 'Event Name');
			var eventName = new FlxUIInputText(150,20,80,"");
			var typeLabel = new FlxText(10, 45, 'Type of Event');
			var eventType = new FlxUIDropDownMenu(10,60,FlxUIDropDownMenu.makeStrIdLabelArray(["BPM Change", "Scroll Speed Change"], true));
			var valueLabel = new FlxText(150, 45, 'Event Value');
			var eventValue = new FlxUIInputText(150,60,80,"");
			var eventSave = new FlxButton(10,155,"Save Event", function() {
				var pog:Song.Event = new Song.Event(currentSelectedEventName,currentEventPosition,HelperFunctions.truncateFloat(Std.parseFloat(savedValue), 3),savedType);
	
				trace("trying to save " + currentSelectedEventName);

				var obj = containsName(pog.name,_song.eventObjects);
				

				if (pog.name == "")
					return;

				trace("yeah we can save it");
	
				if (obj != null)
					_song.eventObjects.remove(obj);
				_song.eventObjects.push(pog);

				trace(_song.eventObjects.length);
				
					TimingStruct.clearTimings();

					var currentIndex = 0;
					for (i in _song.eventObjects)
					{
						var name = Reflect.field(i,"name");
						var type = Reflect.field(i,"type");
						var pos = Reflect.field(i,"position");
						var value = Reflect.field(i,"value");

						trace(i.type);
						if (type == "BPM Change")
						{
							var beat:Float = pos;

							var endBeat:Float = Math.POSITIVE_INFINITY;

							TimingStruct.addTiming(beat,value,endBeat, 0); // offset in this case = start time since we don't have a offset
							
							if (currentIndex != 0)
							{
								var data = TimingStruct.AllTimings[currentIndex - 1];
								data.endBeat = beat;
								data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
								var step = ((60 / data.bpm) * 1000) / 4;
								TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
								TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
							}

							currentIndex++;
						}
					}

					if (pog.type == "BPM Change")
						recalculateAllSectionTimes();


				var listofnames = [];
	
				for (key => value in _song.eventObjects) {
					listofnames.push(value.name);
				  }
		
				listOfEvents.setData(FlxUIDropDownMenu.makeStrIdLabelArray(listofnames, true));

				listOfEvents.selectedLabel = pog.name;

				trace('end');
			});
			var posLabel = new FlxText(150, 85, 'Event Position');
			var eventPos = new FlxUIInputText(150,100,80,"");
			var eventAdd = new FlxButton(95,155,"Add Event", function() {

				var pog:Song.Event = new Song.Event("New Event " + HelperFunctions.truncateFloat(curDecimalBeat, 3),HelperFunctions.truncateFloat(curDecimalBeat, 3),_song.bpm,"BPM Change");
				
				trace("adding " + pog.name);

				var obj = containsName(pog.name,_song.eventObjects);
	
				if (obj != null)
					return;

				trace("yeah we can add it");

				_song.eventObjects.push(pog);

				eventName.text = pog.name;
				eventType.selectedLabel = pog.type;
				eventValue.text = pog.value + "";
				eventPos.text = pog.position + "";
				currentSelectedEventName = pog.name;
				currentEventPosition = pog.position;

				savedType = pog.type;
				savedValue = pog.value + "";

				var listofnames = [];
	
				for (key => value in _song.eventObjects) {
					listofnames.push(value.name);
				  }
		
				listOfEvents.setData(FlxUIDropDownMenu.makeStrIdLabelArray(listofnames, true));

				listOfEvents.selectedLabel = pog.name;

				TimingStruct.clearTimings();

				var currentIndex = 0;
				for (i in _song.eventObjects)
					{
						var name = Reflect.field(i,"name");
						var type = Reflect.field(i,"type");
						var pos = Reflect.field(i,"position");
						var value = Reflect.field(i,"value");

						trace(i.type);
						if (type == "BPM Change")
						{
							var beat:Float = pos;

							var endBeat:Float = Math.POSITIVE_INFINITY;

							TimingStruct.addTiming(beat,value,endBeat, 0); // offset in this case = start time since we don't have a offset
							
							if (currentIndex != 0)
							{
								var data = TimingStruct.AllTimings[currentIndex - 1];
								data.endBeat = beat;
								data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
								var step = ((60 / data.bpm) * 1000) / 4;
								TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
								TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
							}

							currentIndex++;
						}
					}
				trace("BPM CHANGES:");

				for (i in TimingStruct.AllTimings)
					trace(i.bpm + " - START: " + i.startBeat + " - END: " + i.endBeat + " - START-TIME: " + i.startTime);

				recalculateAllSectionTimes();

				regenerateLines();


			});
			var eventRemove = new FlxButton(180,155,"Remove Event", function() {

				trace("lets see if we can remove " + listOfEvents.selectedLabel);

				var obj = containsName(listOfEvents.selectedLabel,_song.eventObjects);

				trace(obj);
	
				if (obj == null)
					return;

				trace("yeah we can remove it it");

				_song.eventObjects.remove(obj);

				var firstEvent = _song.eventObjects[0];

				if (firstEvent == null)
				{
					_song.eventObjects.push(new Song.Event("Init BPM",0,_song.bpm,"BPM Change"));
					firstEvent = _song.eventObjects[0];
				}

				eventName.text = firstEvent.name;
				eventType.selectedLabel = firstEvent.type;
				eventValue.text = firstEvent.value + "";
				eventPos.text = firstEvent.position + "";
				currentSelectedEventName = firstEvent.name;
				currentEventPosition = firstEvent.position;

				savedType = firstEvent.type;
				savedValue = firstEvent.value + '';

				var listofnames = [];
	
				for (key => value in _song.eventObjects) {
					listofnames.push(value.name);
				  }
		
				listOfEvents.setData(FlxUIDropDownMenu.makeStrIdLabelArray(listofnames, true));

				listOfEvents.selectedLabel = firstEvent.name;

				TimingStruct.clearTimings();

				var currentIndex = 0;
				for (i in _song.eventObjects)
					{
						var name = Reflect.field(i,"name");
						var type = Reflect.field(i,"type");
						var pos = Reflect.field(i,"position");
						var value = Reflect.field(i,"value");

						trace(i.type);
						if (type == "BPM Change")
						{
							var beat:Float = pos;

							var endBeat:Float = Math.POSITIVE_INFINITY;

							TimingStruct.addTiming(beat,value,endBeat, 0); // offset in this case = start time since we don't have a offset
							
							if (currentIndex != 0)
							{
								var data = TimingStruct.AllTimings[currentIndex - 1];
								data.endBeat = beat;
								data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
								var step = ((60 / data.bpm) * 1000) / 4;
								TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
								TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
							}

							currentIndex++;
						}
					}

				recalculateAllSectionTimes();

				regenerateLines();


			});
			var updatePos = new FlxButton(150,120,"Update Pos", function() {
				var obj = containsName(currentSelectedEventName,_song.eventObjects);
				if (obj == null)
					return;
				currentEventPosition = curDecimalBeat;
				obj.position = currentEventPosition;
				eventPos.text = currentEventPosition + ""; 
			});

		
	
			var listofnames = [];

			var firstEventObject = null;
	
			for (event in _song.eventObjects) {
				var name = Reflect.field(event,"name");
				var type = Reflect.field(event,"type");
				var pos = Reflect.field(event,"position");
				var value = Reflect.field(event,"value");

				trace(value);

				var eventt = new Song.Event(name,pos,value,type);

				chartEvents.push(eventt);
				listofnames.push(name);
			  }

			_song.eventObjects = chartEvents;

			if (listofnames.length == 0)
				listofnames.push("");

			if (_song.eventObjects.length != 0)
				firstEventObject = _song.eventObjects[0];
			trace("bruh");


			if (firstEvent != "")
			{
				trace(firstEventObject);
				eventName.text = firstEventObject.name;
				trace("bruh");
				eventType.selectedLabel = firstEventObject.type;
				trace("bruh");
				eventValue.text = firstEventObject.value + "";
				trace("bruh");
				currentSelectedEventName = firstEventObject.name;
				trace("bruh");
				currentEventPosition = firstEventObject.position;
				trace("bruh");
				eventPos.text = currentEventPosition + "";
				trace("bruh");
			}

			listOfEvents = new FlxUIDropDownMenu(10,20, FlxUIDropDownMenu.makeStrIdLabelArray(listofnames, true), function(name:String)
				{
					var event = containsName(listOfEvents.selectedLabel,_song.eventObjects);
					
					if (event == null)
						return;
	
					trace('selecting ' + name + ' found: ' + event);
	
					eventName.text = event.name;
					eventValue.text = event.value + "";
					eventPos.text = event.position + "";
					eventType.selectedLabel = event.type;
					currentSelectedEventName = event.name;
					currentEventPosition = event.position;
				});

			eventValue.callback = function(string:String, string2:String)
			{
				trace(string + " - value");
				savedValue = string;
			};
	
			eventType.callback = function(type:String)
			{
				savedType = eventType.selectedLabel;
			};
	
			eventName.callback = function(string:String, string2:String)
			{
				var obj = containsName(currentSelectedEventName,_song.eventObjects);
				if (obj == null)
				{
					currentSelectedEventName = string;
					return;
				}
				obj = containsName(string,_song.eventObjects);
				if (obj != null)
					return;
				obj = containsName(currentSelectedEventName,_song.eventObjects);
				obj.name = string;
				currentSelectedEventName = string;
			};
			trace("bruh");

			Typeables.push(eventPos);
			Typeables.push(eventValue);
			Typeables.push(eventName);

			var tab_events = new FlxUI(null, UI_options);
			tab_events.name = "Events";
			tab_events.add(posLabel);
			tab_events.add(valueLabel);
			tab_events.add(nameLabel);
			tab_events.add(listLabel);
			tab_events.add(typeLabel);
			tab_events.add(eventName);
			tab_events.add(eventType);
			tab_events.add(listOfEvents);
			tab_events.add(eventValue);
			tab_events.add(eventSave);
			tab_events.add(eventAdd);
			tab_events.add(eventRemove);
			tab_events.add(eventPos);
			tab_events.add(updatePos);
			UI_options.addGroup(tab_events);
            
            regenerateLines();
	}

	function addOptionsUI()
        {
            
    
            var hitsounds = new FlxUICheckBox(10, 60, null, null, "Play hitsounds", 100);
            hitsounds.checked = false;
            hitsounds.callback = function()
            {
                playClaps = hitsounds.checked;
            };
    
            var check_mute_inst = new FlxUICheckBox(10, 90, null, null, "Mute Instrumental", 100);
            check_mute_inst.checked = false;
            check_mute_inst.callback = function()
            {
                var vol:Float = 1;
    
                if (check_mute_inst.checked)
                    vol = 0;
    
                FlxG.sound.music.volume = vol;
            };
    
            check_snap = new FlxUICheckBox(80, 25, null, null, "Snap to grid", 100);
            check_snap.checked = defaultSnap;
            // _song.needsVoices = check_voices.checked;
            check_snap.callback = function()
            {
                defaultSnap = check_snap.checked;
                trace('CHECKED!');
            };
    
            var tab_options = new FlxUI(null, UI_options);
            tab_options.name = "Options";
            tab_options.add(hitsounds);
            tab_options.add(check_mute_inst);
            UI_options.addGroup(tab_options);
        }
    
	function recalculateAllSectionTimes()
        {
    
            /*if (TimingStruct.AllTimings.length > 0)
            {
                trace("Song length in MS: " + FlxG.sound.music.length);
    
                for(i in 0...9000000) // REALLY HIGH BEATS just cuz like ig this is the upper limit, I mean ur chart is probably going to run like ass anyways
                {
                    var seg = TimingStruct.getTimingAtBeat(i);
    
                    var time = (i / (seg.bpm / 60)) * 1000;
    
                    if (time > FlxG.sound.music.length)
                        break;
    
                    lengthInBeats = i;
                }
    
                lengthInSteps = lengthInBeats * 4;
    
                trace('LENGTH IN STEPS ' + lengthInSteps + ' | LENGTH IN BEATS ' + lengthInBeats);
            }*/
    
                trace("RECALCULATING SECTION TIMES");
                for (i in 0..._song.notes.length) // loops through sections
                {
                    var section = _song.notes[i];
    
                    var currentBeat = 4 * i;
    
                    var currentSeg = TimingStruct.getTimingAtBeat(currentBeat);
    
                    if (currentSeg == null)
                        return;
    
                    var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);
    
                    section.startTime = (currentSeg.startTime + start) * 1000;
    
                    if (i != 0)
                        _song.notes[i - 1].endTime = section.startTime;
                    section.endTime = Math.POSITIVE_INFINITY;
    
                }
                once = true;
        }
    
        var once = false;
    
	function regenerateLines()
        {
            while(lines.members.length > 0)
            {
                lines.members[0].destroy();
                lines.members.remove(lines.members[0]);
            }
    
            while(texts.members.length > 0)
            {
                texts.members[0].destroy();
                texts.members.remove(texts.members[0]);
            }
            trace("removed lines and texts");
    
            if (_song.eventObjects != null)
                for(i in _song.eventObjects)
                {
                    var seg = _song.notes[curSection];

                    //var posi:Float = i.position %;
                    if(i.position >= (seg.startTime/250) && i.position < (seg.endTime/250))
                    {

                        //var pos = Math.floor(getYfromStrum((i.position - (seg.startTime / 1000.0))*1000)/2 * zoomFactor);
                        var pos = (getYfromStrum((i.position - sectionStartTime()/1000.0)));
                        trace("ABRACADABRA POS = " + pos);
                        //pos = gridBG.y + (pos / (_song.bpm / 120) / 2);
                        //Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)))

                        if (pos < 0)
                            pos = 0;

                        var type = i.type;

                        var text = new FlxText(-190, pos,0,i.name + "\n" + type + "\n" + i.value,12);
                        var line = new FlxSprite(0, pos).makeGraphic(Std.int(GRID_SIZE * 8), 4, FlxColor.BLUE);

                        line.alpha = 0.2;

                        lines.add(line);
                        texts.add(text);

                        add(line);
                        add(text);
                        }
                    }
    
            for (i in sectionRenderes)
            {
                var pos = getYfromStrum(i.section.startTime) * zoomFactor;
                i.icon.y = pos - 75;
    
                var line = new FlxSprite(0, pos).makeGraphic(Std.int(GRID_SIZE * 8), 4, FlxColor.BLACK);
                line.alpha = 0.4;
                lines.add(line);
            }
        }
    
	var stepperDiv:FlxUINumericStepper;
	var check_snap:FlxUICheckBox;
	var listOfEvents:FlxUIDropDownMenu;
	var currentSelectedEventName:String = "";
	var savedType:String = "";
	var savedValue:String = "";
	var currentEventPosition:Float = 0;


	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};


		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		
		var restart = new FlxButton(10,140,"Reset Chart", function()
            {
                for (ii in 0..._song.notes.length)
                {
                    for (i in 0..._song.notes[ii].sectionNotes.length)
                        {
                            _song.notes[ii].sectionNotes = [];
                        }
                }
                resetSection(true);
            });

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);
		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 0.1, 1, 1.0, 5000.0, 1);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var stepperBPMLabel = new FlxText(74,65,'BPM');
		
		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperSpeedLabel = new FlxText(74,80,'Scroll Speed');
		
		var stepperVocalVol:FlxUINumericStepper = new FlxUINumericStepper(10, 95, 0.1, 1, 0.1, 10, 1);
		stepperVocalVol.value = vocals.volume;
		stepperVocalVol.name = 'song_vocalvol';

		var stepperVocalVolLabel = new FlxText(74, 95, 'Vocal Volume');
		
		var stepperSongVol:FlxUINumericStepper = new FlxUINumericStepper(10, 110, 0.1, 1, 0.1, 10, 1);
		stepperSongVol.value = FlxG.sound.music.volume;
		stepperSongVol.name = 'song_instvol';

		var doesloop = new FlxUICheckBox(200, 110, null, null, "Does Loop", 100);
		doesloop.checked = _song.doesLoop;
		// _song.needsVoices = check_voices.checked;
		doesloop.callback = function()
		{
			_song.doesLoop = doesloop.checked;
			trace('LOOP??!');
		};

		var stepperSongVolLabel = new FlxText(74, 110, 'Instrumental Volume');


		var stepperLoopAtStepLabel = new FlxText(200, 125, 'Loop At Step');
		var stepperLoopAtStep:FlxUINumericStepper = new FlxUINumericStepper(200, 140, 1, 0, 0, 999999, 0);
		stepperLoopAtStep.value = _song.loopAtStep;
		stepperLoopAtStep.name = 'song_loopat';

		var stepperLoopToStepLabel = new FlxText(200, 155, 'Loop To Step');
		var stepperLoopToStep:FlxUINumericStepper = new FlxUINumericStepper(200, 170, 1, 0, 0, 999999, 0);
		stepperLoopToStep.value = _song.loopToStep;
		stepperLoopToStep.name = 'song_loopto';

		var opponentHealthLabel = new FlxText(200, 185, 'Opponent Health');
		var stepperOpponentHealth:FlxUINumericStepper = new FlxUINumericStepper(200, 200, 0.05, 2, 0, 999999, 2);
		stepperOpponentHealth.value = _song.opponentHealth;
		stepperOpponentHealth.name = 'song_opponenthealth';

		var startingHealthLabel = new FlxText(200, 215, 'Starting Health');
		var stepperStartingHealth:FlxUINumericStepper = new FlxUINumericStepper(200, 230, 0.05, 1, 0, 999999, 2);
		stepperStartingHealth.value = _song.startingHealth;
		stepperStartingHealth.name = 'song_startinghealth';

		var shiftNoteDialLabel = new FlxText(200, 245, 'Shift Note FWD by (Section)');
		var stepperShiftNoteDial:FlxUINumericStepper = new FlxUINumericStepper(200, 260, 1, 0, -1000, 1000, 0);
		stepperShiftNoteDial.name = 'song_shiftnote';
		var shiftNoteDialLabel2 = new FlxText(200, 275, 'Shift Note FWD by (quarter note)');
		var stepperShiftNoteDialstep:FlxUINumericStepper = new FlxUINumericStepper(200, 290, 1, 0, -1000, 1000, 0);
		stepperShiftNoteDialstep.name = 'song_shiftnotems';
		var shiftNoteDialLabel3 = new FlxText(200, 305, 'Shift Note FWD by (ms)');
		var stepperShiftNoteDialms:FlxUINumericStepper = new FlxUINumericStepper(200, 320, 1, 0, -1000, 1000, 2);
		stepperShiftNoteDialms.name = 'song_shiftnotems';


		var shiftNoteButton:FlxButton = new FlxButton(10, 335, "Shift", function()
		{
			shiftNotes(Std.int(stepperShiftNoteDial.value),Std.int(stepperShiftNoteDialstep.value),Std.int(stepperShiftNoteDialms.value));
		});

		
		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/characterList'));
		var gfVersions:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/gfVersionList'));
		var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/stageList'));
		var noteStyles:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/noteStyleList'));
		var gimmicksList:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/gimmickList'));

		var player1DropDown = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
		});
		player1DropDown.selectedLabel = _song.player1;

		var player1Label = new FlxText(10,80,64,'Player 1');

		var player2DropDown = new FlxUIDropDownMenu(140, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
		});
		player2DropDown.selectedLabel = _song.player2;

		var player2Label = new FlxText(140,80,64,'Player 2');

		var gfVersionDropDown = new FlxUIDropDownMenu(10, 200, FlxUIDropDownMenu.makeStrIdLabelArray(gfVersions, true), function(gfVersion:String)
			{
				_song.gfVersion = gfVersions[Std.parseInt(gfVersion)];
			});
		gfVersionDropDown.selectedLabel = _song.gfVersion;

		var gfVersionLabel = new FlxText(10,180,64,'Girlfriend');

		var stageDropDown = new FlxUIDropDownMenu(140, 200, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(stage:String)
			{
				_song.stage = stages[Std.parseInt(stage)];
			});
		stageDropDown.selectedLabel = _song.stage;
		
		var stageLabel = new FlxText(140,180,64,'Stage');

		var noteStyleDropDown = new FlxUIDropDownMenu(10, 300, FlxUIDropDownMenu.makeStrIdLabelArray(noteStyles, true), function(noteStyle:String)
			{
				_song.noteStyle = noteStyles[Std.parseInt(noteStyle)];
			});
		noteStyleDropDown.selectedLabel = _song.noteStyle;

		var noteStyleLabel = new FlxText(10,280,64,'Note Skin');

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);
		tab_group_song.add(restart);
		tab_group_song.add(check_voices);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperBPMLabel);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(stepperSpeedLabel);
		tab_group_song.add(stepperVocalVol);
		tab_group_song.add(stepperVocalVolLabel);
		tab_group_song.add(stepperSongVol);
		tab_group_song.add(stepperSongVolLabel);
        tab_group_song.add(shiftNoteDialLabel);
        tab_group_song.add(stepperShiftNoteDial);
        tab_group_song.add(shiftNoteDialLabel2);
        tab_group_song.add(stepperShiftNoteDialstep);
        tab_group_song.add(shiftNoteDialLabel3);
        tab_group_song.add(stepperShiftNoteDialms);
        tab_group_song.add(shiftNoteButton);
        
        tab_group_song.add(doesloop);
        tab_group_song.add(stepperLoopAtStepLabel);
        tab_group_song.add(stepperLoopAtStep);
        tab_group_song.add(stepperLoopToStepLabel);
        tab_group_song.add(stepperLoopToStep);
        tab_group_song.add(opponentHealthLabel);
        tab_group_song.add(stepperOpponentHealth);
        tab_group_song.add(startingHealthLabel);
        tab_group_song.add(stepperStartingHealth);


		var tab_group_assets = new FlxUI(null, UI_box);
		tab_group_assets.name = "Assets";
		tab_group_assets.add(noteStyleDropDown);
		tab_group_assets.add(noteStyleLabel);
		tab_group_assets.add(gfVersionDropDown);
		tab_group_assets.add(gfVersionLabel);
		tab_group_assets.add(stageDropDown);
		tab_group_assets.add(stageLabel);
		tab_group_assets.add(player1DropDown);
		tab_group_assets.add(player2DropDown);
		tab_group_assets.add(player1Label);
		tab_group_assets.add(player2Label);

		UI_box.addGroup(tab_group_song);
		UI_box.addGroup(tab_group_assets);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		var stepperLengthLabel = new FlxText(74,10,'Section Length (in steps)');

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 132, 1, 1, -999, 999, 0);
		var stepperCopyLabel = new FlxText(174,132,'sections back');

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear Section", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap Section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
				updateGrid();
			}
		});
		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Camera Points to P1?", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alternate Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperLengthLabel);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(stepperCopyLabel);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
    var noteTypeDropDown:FlxUIDropDownMenu;
	var tab_group_note:FlxUI;
	
	function addNoteUI():Void
	{
		tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		writingNotesText = new FlxUIText(20,100, 0, "");
		writingNotesText.setFormat("Arial",20,FlxColor.WHITE,FlxTextAlign.LEFT,FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * _song.notes[curSection].lengthInSteps * 4);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var stepperSusLengthLabel = new FlxText(74,10,'Note Sustain Length');
    

		var applyLength:FlxButton = new FlxButton(10, 100, 'Apply Data');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(stepperSusLengthLabel);
		tab_group_note.add(applyLength);


		var noteTypes:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/noteTypesList'));
		
		noteTypeDropDown = new FlxUIDropDownMenu(10, 50, FlxUIDropDownMenu.makeStrIdLabelArray(noteTypes, true), function(noteType:String)
			{
				noteTypeDropDown.selectedLabel = currentNoteType;
                updateNoteUI();
                updateGrid();
			});
		noteTypeDropDown.name = 'note_noteType';
		
		var noteTypeLabel = new FlxText(74,10,'Note Sustain Length');

		var stepperSusLengthLabel = new FlxText(74,30,'Note Type');

		var applyLength:FlxButton = new FlxButton(100, 250, 'Apply Data');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(stepperSusLengthLabel);
		tab_group_note.add(applyLength);
		tab_group_note.add(noteTypeLabel);
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
		/*player2 = new Character(0,gridBG.y, _song.player2);
		player1 = new Boyfriend(player2.width * 0.2,gridBG.y + player2.height, _song.player1);

		player1.y = player1.y - player1.height;

		player2.setGraphicSize(Std.int(player2.width * 0.2));
		player1.setGraphicSize(Std.int(player1.width * 0.2));

		UI_box.add(player1);
		UI_box.add(player2);*/

	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		FlxG.sound.playMusic(Paths.inst(daSong), 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function()
		{
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);

		 */
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Camera Points to P1?':
					_song.notes[curSection].mustHitSection = check.checked;
				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alternate Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				if (nums.value <= 4)
					nums.value = 4;
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				if (nums.value <= 0)
					nums.value = 0;
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				if (nums.value <= 0)
					nums.value = 1;
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if (wname == 'note_susLength')
			{
				if (curSelectedNote == null)
					return;

				if (nums.value <= 0)
					nums.value = 0;
				curSelectedNote[2] = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm')
			{
				if (nums.value <= 0.1)
					nums.value = 0.1;
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}else if (wname == 'song_vocalvol')
			{
				if (nums.value <= 0.1)
					nums.value = 0.1;
				vocals.volume = nums.value;
			}else if (wname == 'song_instvol')
			{
				if (nums.value <= 0.1)
					nums.value = 0.1;
				FlxG.sound.music.volume = nums.value;
			}else if (wname == 'song_loopat')
			{
				if (nums.value <= 0.1)
					nums.value = 0.1;
				_song.loopAtStep = Math.floor(nums.value);
			}
			else if (wname == 'song_loopto')
			{
				if (nums.value <= 0.1)
					nums.value = 0.1;
				_song.loopToStep = Math.floor(nums.value);
			}
			
			else if (wname == 'song_opponenthealth')
			{
				if (nums.value <= 0.1)
					nums.value = 0.1;
				_song.opponentHealth = nums.value;
			}
			else if (wname == 'song_startinghealth')
			{
				if (nums.value <= 0.1)
					nums.value = 0.1;
				_song.startingHealth = nums.value;
			}
			
		}		
        else if (id == FlxUIDropDownMenu.CLICK_EVENT && (sender is FlxUIDropDownMenu))
		{
			var data:FlxUIDropDownMenu = cast sender;
			var wname = data.name;
			FlxG.log.add(wname);
			if (wname == 'note_noteType')
				{
					if (curSelectedNote == null)
						return;
	
					if (data.selectedLabel == "")
						data.selectedLabel = "normal";
					curSelectedNote[3] = data.selectedLabel;
					updateGrid();
				}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[curSection].changeBPM)
				return _song.notes[curSection].lengthInSteps * (_song.notes[curSection].bpm / _song.bpm);
			else
				return _song.notes[curSection].lengthInSteps;
	}*/

	function stepStartTime(step):Float
	{
		return _song.bpm / (step / 4) / 60;
	}

	function sectionStartTime():Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	var writingNotes:Bool = false;
	var doSnapShit:Bool = true;

	override function update(elapsed:Float)
	{
		updateHeads();

		snapText.text = "Snap: 1/" + snap + " (" + (doSnapShit ? "Control to disable" : "Snap Disabled, Control to renable") + ")\nAdd Notes: 1-8 (or click)\n";

		curStep = recalculateSteps();

		/*if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.RIGHT)
			snap = snap * 2;
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.LEFT)
			snap = Math.round(snap / 2);
		if (snap >= 192)
			snap = 192;
		if (snap <= 1)
			snap = 1;*/

		if (FlxG.keys.justPressed.CONTROL)
			doSnapShit = !doSnapShit;

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		var left = FlxG.keys.justPressed.ONE;
		var down = FlxG.keys.justPressed.TWO;
		var up = FlxG.keys.justPressed.THREE;
		var right = FlxG.keys.justPressed.FOUR;
		var leftO = FlxG.keys.justPressed.FIVE;
		var downO = FlxG.keys.justPressed.SIX;
		var upO = FlxG.keys.justPressed.SEVEN;
		var rightO = FlxG.keys.justPressed.EIGHT;

		var pressArray = [left, down, up, right, leftO, downO, upO, rightO];
		var delete = false;
		curRenderedNotes.forEach(function(note:Note)
			{
				if (strumLine.overlaps(note) && pressArray[Math.floor(Math.abs(note.noteData))])
				{
					deleteNote(note);
					delete = true;
					trace('deelte note');
				}
			});
		for (p in 0...pressArray.length)
		{
			var i = pressArray[p];
			if (i && !delete)
			{
				addNote(new Note(Conductor.songPosition,p,null,false,true,currentNoteType));
			}
		}

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));
		

		if (playClaps)
            {
                curRenderedNotes.forEach(function(note:Note)
                {
                    if (FlxG.sound.music.playing)
                    {
                        if (strumLine.overlaps(note))
                        {
                        if(!claps.contains(note))
                            {
                                claps.push(note);
                                if (note.noteType=="sun" || note.noteType=="sun-extra") FlxG.sound.play(Paths.sound('sunCollect'));
                                else if(note.noteType=="sun-bomb") {};
                                else if(_song.notes[curSection].mustHitSection) FlxG.sound.play(Paths.sound('CLAP'));
                                else FlxG.sound.play(Paths.sound('SNAP'));
                            }
                        }
                    }
                }
                );
            }
		/*curRenderedNotes.forEach(function(note:Note) {
			if (strumLine.overlaps(note) && strumLine.y == note.y) // yandere dev type shit
			{
				if (_song.notes[curSection].mustHitSection)
					{
						trace('must hit ' + Math.abs(note.noteData));
						if (note.noteData < 4)
						{
							switch (Math.abs(note.noteData))
							{
								case 2:
									player1.playAnim('singUP', true);
								case 3:
									player1.playAnim('singRIGHT', true);
								case 1:
									player1.playAnim('singDOWN', true);
								case 0:
									player1.playAnim('singLEFT', true);
							}
						}
						if (note.noteData >= 4)
						{
							switch (note.noteData)
							{
								case 6:
									player2.playAnim('singUP', true);
								case 7:
									player2.playAnim('singRIGHT', true);
								case 5:
									player2.playAnim('singDOWN', true);
								case 4:
									player2.playAnim('singLEFT', true);
							}
						}
					}
					else
					{
						trace('hit ' + Math.abs(note.noteData));
						if (note.noteData < 4)
						{
							switch (Math.abs(note.noteData))
							{
								case 2:
									player2.playAnim('singUP', true);
								case 3:
									player2.playAnim('singRIGHT', true);
								case 1:
									player2.playAnim('singDOWN', true);
								case 0:
									player2.playAnim('singLEFT', true);
							}
						}
						if (note.noteData >= 4)
						{
							switch (note.noteData)
							{
								case 6:
									player1.playAnim('singUP', true);
								case 7:
									player1.playAnim('singRIGHT', true);
								case 5:
									player1.playAnim('singDOWN', true);
								case 4:
									player1.playAnim('singLEFT', true);
							}
						}
					}
			}
		});*/

		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1))
		{
			trace(curStep);
			trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
			trace('DUMBSHIT');

			if (_song.notes[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else
						{
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
				{
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			lastSection = curSection;

			PlayState.SONG = _song;
			FlxG.sound.music.stop();
			FlxG.sound.muteKeys = [FlxKey.ZERO,FlxKey.NUMPADZERO];
			vocals.stop();
			LoadingState.loadAndSwitchState(new PlayState());
		}

		if (FlxG.keys.justPressed.E)
		{
			changeNoteSustain(Conductor.stepCrochet);
		}
		if (FlxG.keys.justPressed.Q)
		{
			changeNoteSustain(-Conductor.stepCrochet);
		}

		if (FlxG.keys.justPressed.TAB)
		{
			if (FlxG.keys.pressed.SHIFT)
			{
				UI_box.selected_tab -= 1;
				if (UI_box.selected_tab < 0)
					UI_box.selected_tab = 2;
			}
			else
			{
				UI_box.selected_tab += 1;
				if (UI_box.selected_tab >= 3)
					UI_box.selected_tab = 0;
			}
		}

		if (!typingShit.hasFocus)
		{

			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.Z && lastNote != null)
				{
					trace(curRenderedNotes.members.contains(lastNote) ? "delete note" : "add note");
					if (curRenderedNotes.members.contains(lastNote))
						deleteNote(lastNote);
					else 
						addNote(lastNote);
				}
			}

			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;
			if (!FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
					changeSection(curSection + shiftThing);
				if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
					changeSection(curSection - shiftThing);
			}	
			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					vocals.pause();
					claps.splice(0, claps.length);
				}
				else
				{
					vocals.play();
					FlxG.sound.music.play();
				}
			}

			if (FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			
			if (FlxG.sound.music.time < 0 || curStep < 0)
				FlxG.sound.music.time = 0;

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				claps.splice(0, claps.length);

				var stepMs = curStep * Conductor.stepCrochet;


				trace(Conductor.stepCrochet / snap);

				if (doSnapShit)
					FlxG.sound.music.time = stepMs - (FlxG.mouse.wheel * Conductor.stepCrochet / snap);
				else
					FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
				trace(stepMs + " + " + Conductor.stepCrochet / snap + " -> " + FlxG.sound.music.time);

				vocals.time = FlxG.sound.music.time;
			}

			if (!FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();
					claps.splice(0, claps.length);

					var daTime:Float = 700 * FlxG.elapsed;

					if (FlxG.keys.pressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
			else
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = Conductor.stepCrochet * 2;

					if (FlxG.keys.justPressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
		}

		_song.bpm = tempBpm;

		/* if (FlxG.keys.justPressed.UP)
				Conductor.changeBPM(Conductor.bpm + 1);
			if (FlxG.keys.justPressed.DOWN)
				Conductor.changeBPM(Conductor.bpm - 1); */

		bpmTxt.text = bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ "\nSection: "
			+ curSection 
			+ "\nCurStep: " 
			+ curStep;
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	override function beatHit() 
	{
		trace('beat');

		super.beatHit();
		if (!player2.animation.curAnim.name.startsWith("sing"))
		{
			player2.playAnim('idle');
		}
		player1.dance();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		trace('changing section' + sec);

		if (_song.notes[sec] != null)
		{
			trace('naw im not null');
			curSection = sec;

			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
            regenerateLines();
		}
		else
			trace('bro wtf I AM NULL');
	}

	function copySection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;
	}

	function updateHeads():Void
	{
		if (check_mustHitSection.checked)
		{
			leftIcon.animation.play(_song.player1);
			rightIcon.animation.play(_song.player2);
		}
		else
		{
			leftIcon.animation.play(_song.player2);
			rightIcon.animation.play(_song.player1);
		}
		
		leftIcon.animation.curAnim.curFrame = 1;
		rightIcon.animation.curAnim.curFrame = 1;
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	function updateGrid():Void
	{
		remove(gridBG);
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * _song.notes[curSection].lengthInSteps);
        add(gridBG);

		remove(gridBlackLine);
		gridBlackLine = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);
		
		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		while (curRenderedSustains.members.length > 0)
		{
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						trace('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		for (i in sectionInfo)
		{
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];
			var daType = i[3];

			var note:Note = new Note(daStrumTime, daNoteInfo % 4,null,false,true,daType);
			note.sustainLength = daSus;
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.x = Math.floor(daNoteInfo * GRID_SIZE);
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)));

			if (curSelectedNote != null)
				if (curSelectedNote[0] == note.strumTime)
					lastNote = note;

			curRenderedNotes.add(note);

			if (daSus > 0)
			{
				var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
					note.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * _song.notes[curSection].lengthInSteps, 0, gridBG.height)));
				curRenderedSustains.add(sustainVis);
			}
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var daPos:Float = 0;
		
		var sec:SwagSection = {
			startTime: daPos,
			endTime: Math.POSITIVE_INFINITY,
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in getSectionByTime(note.strumTime).sectionNotes)
		{
			if (i[0] == note.strumTime && i[1] == note.rawNoteData)
			{
				curSelectedNote = getSectionByTime(note.strumTime).sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}


	function deleteNote(note:Note):Void
		{
			lastNote = note;
			for (i in _song.notes[curSection].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] % 4 == note.noteData)
				{
					_song.notes[curSection].sectionNotes.remove(i);
				}
			}
	
			updateGrid();
		}

	function clearSection():Void
	{
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function newSection(lengthInSteps:Int = 16,mustHitSection:Bool = false,altAnim:Bool = true):SwagSection
		{

			var daPos:Float = 0;
					
			var currentSeg = TimingStruct.AllTimings[TimingStruct.AllTimings.length - 1];

			var currentBeat = 4;

			for(i in _song.notes)
				currentBeat += 4;

			if (currentSeg == null)
				return null;

			var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);

			daPos = (currentSeg.startTime + start) * 1000;

			var sec:SwagSection = {
				startTime: daPos,
				endTime: Math.POSITIVE_INFINITY,
				lengthInSteps: lengthInSteps,
				bpm: _song.bpm,
				changeBPM: false,
				mustHitSection: mustHitSection,
				sectionNotes: [],
				typeOfSection: 0,
				altAnim: altAnim
			};


			return sec;
		}
		
// OLD 1.5.2 CODE

/*
	private function newSection(lengthInSteps:Int = 16,mustHitSection:Bool = false,altAnim:Bool = true):SwagSection
		{
			var daPos:Float = 0;
			
			var currentSeg = TimingStruct.AllTimings[TimingStruct.AllTimings.length - 1];
			
			daPos = (currentSeg.startTime + start) * 1000;
			
			var sec:SwagSection = {
				startTime: daPos,
				endTime: Math.POSITIVE_INFINITY,
				lengthInSteps: lengthInSteps,
				bpm: _song.bpm,
				changeBPM: false,
				mustHitSection: mustHitSection,
				sectionNotes: [],
				typeOfSection: 0,
				altAnim: altAnim
			};

			return sec;
		}
*/
	function shiftNotes(measure:Int=0,step:Int=0,ms:Int = 0):Void
		{
			var newSong = [];
			
			var millisecadd = (((measure*4)+step/4)*(60000/_song.bpm))+ms;
			var totaladdsection = Std.int((millisecadd/(60000/_song.bpm)/4));
			trace(millisecadd,totaladdsection);
			if(millisecadd > 0)
				{
					for(i in 0...totaladdsection)
						{
							newSong.unshift(newSection());
						}
				}
			for (daSection1 in 0..._song.notes.length)
				{
					newSong.push(newSection(16,_song.notes[daSection1].mustHitSection,_song.notes[daSection1].altAnim));
				}
	
			for (daSection in 0...(_song.notes.length))
			{
				var aimtosetsection = daSection+Std.int((totaladdsection));
				if(aimtosetsection<0) aimtosetsection = 0;
				newSong[aimtosetsection].mustHitSection = _song.notes[daSection].mustHitSection;
				newSong[aimtosetsection].altAnim = _song.notes[daSection].altAnim;
				//trace("section "+daSection);
				for(daNote in 0...(_song.notes[daSection].sectionNotes.length))
					{	
						var newtiming = _song.notes[daSection].sectionNotes[daNote][0]+millisecadd;
						if(newtiming<0)
						{
							newtiming = 0;
						}
						var futureSection = Math.floor(newtiming/4/(60000/_song.bpm));
						_song.notes[daSection].sectionNotes[daNote][0] = newtiming;
						newSong[futureSection].sectionNotes.push(_song.notes[daSection].sectionNotes[daNote]);
	
						//newSong.notes[daSection].sectionNotes.remove(_song.notes[daSection].sectionNotes[daNote]);
					}
	
			}
			//trace("DONE BITCH");
			_song.notes = newSong;
			updateGrid();
			updateSectionUI();
			updateNoteUI();
		}
		
	public function getSectionByTime(ms:Float, ?changeCurSectionIndex:Bool = false):SwagSection
	{
		var index = 0;



		for (i in _song.notes)
		{
			if (ms >= i.startTime && ms < i.endTime)
			{
				if (changeCurSectionIndex)
					curSection = index;
				return i;
			}
			index++;
		}


		return null;
	}
	
	private function addNote(?n:Note):Void
	{
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus = 0;

		if (n != null)
			_song.notes[curSection].sectionNotes.push([n.strumTime, n.noteData, n.sustainLength]);
		else
			_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus]);

		var thingy = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		curSelectedNote = thingy;

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}
	function getYForLines(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, sectionStartTime()/ 1000.0,_song.notes[curSection].endTime / 1000.0, 0, GRID_SIZE*_song.notes[curSection].lengthInSteps);
	}

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;

			for (i in _song.notes)
			{
				var swagLength = i.lengthInSteps;

				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;

				daLength += swagLength;

				if (sec != null && sec == i)
				{
					trace('swag loop??');
					break;
				}
			}

			return daLength;
	}*/
	private var daSpacing:Float = 0.3;

	function loadLevel():Void
	{
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
		LoadingState.loadAndSwitchState(new ChartingState());
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		LoadingState.loadAndSwitchState(new ChartingState());
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}
