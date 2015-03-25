package es.guillermoorellana.countUP;

import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxPoint;
import flixel.util.FlxSave;

class PlayState extends FlxState {
    private static inline var NUM_BOXES:Int = 4;

    private static inline var BOX_SIDE:Int = 128;

    private static inline var BOX_PADDING:Int = 3;

    private static inline var TOP_PADDING:Int = 150;

    private static inline var TIME_CONSTANT:Int = 800;

// Here's the FlxSave variable this is what we're going to be saving to.
    private var _gameSave:FlxSave;

// We're just going to drop a bunch of boxes into a group
    private var _boxGroup:FlxTypedGroup<NumberedButton>;

// We'll use these variables for the dragging
    private var dragOffset:FlxPoint;
    private var _dragging:Bool = false;
    private var _pressTarget:NumberedButton;

// Buttons for the demo
    private var _saveButton:FlxButton;
    private var _loadButton:FlxButton;
    private var _clearButton:FlxButton;

// The top text that yells at you
    private var _topText:FlxText;

    private var _timeleftText:FlxText;
    private var _timeleft:Int;

    private var _nextShouldBe:Int;
    private var magicNumber:Int;
    private var nextCandidates:Array<Int>;

    private var _goGroup:FlxGroup;
    private var _goButton:FlxButton;

    private var _highscoreText:FlxText;
    private var _highscore:Int;

    private var _running:Bool;
    private var _gameover:Bool;

    override public function create():Void {
        _gameSave = new FlxSave();
        _gameSave.bind("SaveDemo");


//Since we need the text before the usual end of the demo we'll initialize it up here.
        _topText = new FlxText(0, 2, FlxG.width, "Welcome!");
        _topText.alignment = 'center';

        _timeleftText = new FlxText(0, 30, FlxG.width, "~");
        _timeleftText.alignment = 'center';
        _timeleftText.size = 30;


        add(_timeleftText);

        var dragText:FlxText = new FlxText(5, FlxG.height - 100, FlxG.width, "Tap in ascending order");
        dragText.color = FlxColor.WHITE;
        dragText.alpha = 0.2;
        dragText.size = 30;
        dragText.alignment = 'center';
        add(dragText);

        if (_gameSave.data.highscore != null) {
            _highscore = _gameSave.data.highscore;
        } else {
            _highscore = 0;
        }
        _highscoreText = new FlxText(0, 100, FlxG.width, 'Highscore: $_highscore');
        _highscoreText.alignment = 'center';
        _highscoreText.size = 30;
        add(_highscoreText);


        _goButton = new FlxButton(20, 20, 'GAME OVER', gameOverButton);
        _goButton.makeGraphic(FlxG.width - 40, FlxG.height - 40, FlxColor.RED);
        _goButton.label = new FlxText(0, 150, _goButton.width, 'GAME OVER');
        _goButton.label.size = 30;
        _goButton.label.alignment = 'center';

        _goGroup = new FlxGroup();
        _goGroup.add(_goButton);
        _goGroup.visible = false;

//Set out offset to non-null here
        dragOffset = FlxPoint.get(0, 0);

        _boxGroup = new FlxTypedGroup<NumberedButton>();

        var boxpos:Array<Array<Float>> = [[], [], [], []];
        boxpos[0] = [FlxG.width / 2 - BOX_SIDE - BOX_PADDING, TOP_PADDING];
        boxpos[1] = [FlxG.width / 2 + BOX_PADDING, TOP_PADDING];
        boxpos[2] = [FlxG.width / 2 - BOX_SIDE - BOX_PADDING, TOP_PADDING + BOX_SIDE + BOX_PADDING];
        boxpos[3] = [FlxG.width / 2 + BOX_PADDING, TOP_PADDING + BOX_SIDE + BOX_PADDING];

        for (i in 0...NUM_BOXES) {
            var box:NumberedButton;
            box = new NumberedButton(boxpos[i][0], boxpos[i][1], Std.string(i + 1));

            box.makeGraphic(BOX_SIDE, BOX_SIDE, FlxColor.GRAY);
            box.label = new FlxText(0, 20, box.width, '');
            box.label.size = 30;
            box.label.alignment = 'center';

            _boxGroup.add(box);
        }
        add(_boxGroup);//Add the group to the state


// Get out buttons set up along the bottom of the screen
        var buttonY:Int = FlxG.height - 22;
        _clearButton = new FlxButton(202, buttonY, "Reset Game", resetGame);
        add(_clearButton);

// Let's not forget about our old text, which needs to be above everything else
        add(_topText);

        add(_goGroup);

        resetGame();
    }

    override public function update():Void {
// This is just to make the text at the top fade out
        if (_topText.alpha > 0) {
            _topText.alpha -= .005;
        }

        if (_running) {
            _timeleft -= Math.floor(FlxG.elapsed * 1000) + 100;
            if (_timeleft <= 0) {
                _timeleft = 0;
                _running = false;
                trace('timeout');
                gameOver();
            }
        }

        _timeleftText.text = '$_timeleft ms';

        super.update();

        if (!_gameover && FlxG.mouse.justPressed) {
            for (i in 0...NUM_BOXES) {
                var a:NumberedButton = cast(_boxGroup.members[i], NumberedButton);

                if (a.status == FlxButton.PRESSED) {
                    _pressTarget = a;

                } else {
                }

            }
        }

// If you let go, then release that box!
        if (FlxG.mouse.justReleased) {
            if (_pressTarget != null) {
                trace('pressed ' + _pressTarget.get_num());
                if (!_running && _pressTarget.get_num() == 1) {
                    trace('running');
                    _running = true;
                }
                if (_running && _pressTarget.get_num() == _nextShouldBe) {
                    _nextShouldBe++;
                    trace('correct');
                    _timeleft += TIME_CONSTANT;
                    _pressTarget.set_num(generate_next());
                } else {
                    gameOver();
                }
            }
            _pressTarget = null;
        }

// And lets move the box around
        if (_dragging) {
        }
    }

    private function generate_next():Int {
        if (nextCandidates.length == 0) {
            magicNumber += NUM_BOXES;
            for (i in 0...NUM_BOXES) {
                nextCandidates.push(magicNumber + i);
            }
            nextCandidates = randomArray(nextCandidates);
        }
        return nextCandidates.shift();

    }

    private function randomArray(_array:Array<Int>):Array<Int> {
        var l:Int = _array.length;
        var mixed:Array<Int> = _array.copy();
        var rn:Int;
        var it:Int;
        var el:Int;
        for (i in 0..._array.length) {
            el = mixed[i];
            rn = Math.floor(Math.random() * l);
            mixed[i] = mixed[rn];
            mixed[rn] = el;
        }
        return mixed;
    }

    private function resetGame() {
        for (i in 0...NUM_BOXES) {
            var a:NumberedButton = cast(_boxGroup.members[i], NumberedButton);
            a.set_num(i + 1);
        }
        trace('reset game');
        _nextShouldBe = 1;
        magicNumber = NUM_BOXES + 1;
        nextCandidates = randomArray([5, 6, 7, 8]);
        _running = false;
        _gameover = false;
        _timeleft = 15000;
        _goGroup.visible = false;
    }

    private function gameOver() {
        trace('gameover');
        _gameover = true;
        _goGroup.visible = true;

        if (_nextShouldBe - 1 > _highscore) {
            trace('highscore');
            _highscore = _nextShouldBe - 1;
            _gameSave.data.highscore = _highscore;
            _gameSave.flush();
            _highscoreText.text = 'Highscore: $_highscore';
        }
        _running = false;
    }

    private function gameOverButton() {
        if (_gameover) {
            resetGame();
            _gameover = false;
        }
    }

/**
	 * Called when the user clicks the 'Save Locations' button
	 */

    private function onSave():Void {
// Do we already have a save? if not then we need to make one
        if (_gameSave.data.boxPositions == null) {
// Let's make a new array at the location data/
// don't worry, if its not there - then flash will make a new variable there
// You can also do something like gameSave.data.randomBool = true;
// and if randomBool didn't exist before, then flash will create a boolean there.
// though it's best to make a new type() before setting it, so you know the correct type is kept
            _gameSave.data.boxPositions = new Array();

            for (i in 0...NUM_BOXES) {
                var box:FlxButton = _boxGroup.members[i];
                _gameSave.data.boxPositions.push(FlxPoint.get(box.x, box.y));
            }

            _topText.text = "Created a new save, and saved positions";
            _topText.alpha = 1;
        }
        else {
// So we already have some save data? lets overwrite the data WITHOUT ASKING! oooh so bad :P
// Now we're not doing a real for-loop here, because i REALLY like for each, so we'll need our own index count
            var tempCount:Int = 0;

// For each button in the group boxGroup - I'm sure you see why I like this already
            for (i in 0...NUM_BOXES) {
                var box:FlxButton = _boxGroup.members[i], FlxButton;
                _gameSave.data.boxPositions[tempCount] = FlxPoint.get(box.x, box.y);
                tempCount++;
            }

            _topText.text = "Overwrote old positions";
            _topText.alpha = 1;
        }
        _gameSave.flush();
    }

/**
	 * Called when the user clicks the 'Load Locations' button 
	 */

    private function onLoad():Void {
// Loading what? Theres no save data!
        if (_gameSave.data.boxPositions == null) {
            _topText.text = "Failed to load - There's no save";
            _topText.alpha = 1;
        }
        else {
// Note that above I saved the positions as an array of FlxPoints, When the SWF is closed and re-opened the Types in the
// array lose their type, and for some reason cannot be re-cast as a FlxPoint. They become regular Flash Objects with the correct
// variables though, so you're safe to use them - just your IDE won't highlight recognize and highlight the variables
            var tempCount:Int = 0;

            for (i in 0...NUM_BOXES) {
                var box:FlxButton = _boxGroup.members[i];
                box.x = _gameSave.data.boxPositions[tempCount].x;
                box.y = _gameSave.data.boxPositions[tempCount].y;
                tempCount++;
            }

            _topText.text = "Loaded positions";
            _topText.alpha = 1;
        }
    }

/**
	 * Called when the user clicks the 'Clear Save' button
	 */

    private function onClear():Void {
// Lets just wipe the whole boxPositions array
        _gameSave.data.boxPositions = null;
        _gameSave.flush();
        _topText.text = "Save erased";
        _topText.alpha = 1;
    }
}

private class NumberedButton extends FlxButton {

    @:isVar public var num(get, set):Int = 0;

    public function new(X:Float = 0, Y:Float = 0, ?Text:String, ?OnClick:Void -> Void) {
        super(X, Y, Text, OnClick);
    }

    public function get_num():Int {return num;}

    public function set_num(n:Int):Int {
        num = n;
        set_text(Std.string(n));
        return n;
    }


}