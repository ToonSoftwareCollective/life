import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0

Screen {
    id                        : lifeScreen

    // A developer may want to see some logging
    property bool debug       : true
    property bool useTestData : false
    property bool useJacksData : false

/*

 Hi, so you got here, very welcome to you.

 Further below is a section about how this app works.
 
 This section is about adding presets as Examples and Themes.
 
 For a Theme skip the next 5 points and read on from there
 
 To add an Example you want to know how to build it and send it to me :

 1) To start have a look on your Toon and select the example
    "Captured Cross" and switch to the Life screen.
    On the Life screen click "No Clicks/Click Cells" so you see the grid.

 2) Think there is a rectangle around the live cells.
    The upper left cell in your rectangle is just to the left of the 
    upper cell which is alive. 
    This cell which is not alive has row,column coordinates 0,0.

 3) Rows numbers count UP when going DOWN and column numbers count up
    when going to the right.
    The live cell on top has coordinates 0,1 because it is in column 1
    1 Row lower is row 1 with 3 cells :  1,0  ;  1,1  ;  1,2 
    1 Row lower is row 2 with 3 cells :  2,0  ;  2,1  ;  2,2
    Coordinates are what you need to describe your example.

 4) To build and test your example you can resize the screen on the
    Presets screen, then go to the Life screen and select Wall or Wrap
    mode and click "No Clicks/Click Cells" so you see the grid.
    Click Clear to clear the screen and start clicking the cells.
    When ready...
    Note the coordinates of the cells or make a picture with your phone.
    Click Start Life to test and repeat until ready.

 5) Put your example in lifeData.json in my github repository
    https://github.com/JackV2020/appDataTest (fork, add, PR etc.)
    The first entry is "CommentsExamples" and is about all the fields.
    You may want to check "Captured Cross" which you checked in 3).
    This is one of the few using SetRowsCols. The Positioning is
    [1,1,1,1]. First 1 puts the composition on row 1, second 1 puts it
    on column 1. Third 1 makes rows to be added downwards and fourth 1
    makes columns be added to the right. You may also want to check
    the positioning of "3 Small Spaceships" which uses different numbers
    and also a -1 for the row direction.

 To add a Theme you want to know how to build it and send it to me :

 1) To get started you open lifeData.json in lifeData in my github repository
    https://github.com/JackV2020/appDataTest
    and find the section "CommentsThemes"
    
 2) Select a theme on your Toon and compare what it looks like with
    what you see in the section "lifeThemes" in lifeData.json. 
    Do this for some themes to get an idea what is possible and what
    values you may need for your theme.

 3) Put your theme in lifeData.json in my github repository
    https://github.com/JackV2020/appDataTest (fork, add, PR etc.)

*/


/*

The way it works.....

The Game of Life happens in a grid.
I use a GridView to visualise that grid with cells.
Each cell has a row number and a column number in the grid.
The upper left cell is at row 0 and column 0.
Living and dead cells each have their own color.
The 2 colors of the cells are controlled by the model lifeModel.
A model can be seen as an array which fills the grid from left to right
and from top to bottom.
The model lifeModel has an entry for each cell and each entry has an
index and a lifeState which is either true for alive or false for dead.

The rules of the game are :
1) Any live cell with two or three live neighbours survives.
2) Any dead cell with three live neighbours becomes a live cell.
3) All other live cells die in the next generation.

In the algorithms below I implement these rules as :
A) Any dead cell with three live neighbours becomes a live cell.
1) and 3) above combined in a different rule :
B) Any live cell not having two or three live neighbours dies.

It is not possible to apply the rules direct to the array while checking
the number of neighbours of the cells because changing a cell changes
the count of neighbours of already checked cells.

This app has a way to tackle that.
When you have a more efficient way, please let me know.

The approach of the algorithm below covers 2 implementations in 1.
One implementation is where the organisms formed by the cells run into
4 walls and the other is where the opposite walls and all 4 corners of
the grid are connected so life can porogress to the other side.

To ease calculations there is an extra array for 'an hidden grid' with
2 more rows and 2 more columns than the GridView.

Picture yourself the hidden array as a grid with the smaller grid array
on it so that the smaller grid [0,0] is at the hidden grid [1,1]
resulting in an extra row above and below and left and right of the
visble grid on screen.

Before we start the application to run we need to bring some cells alive
by either clicking them on the screen or choosing a preset setup.
When a cell comes alive during setup the cell directly below it in the
hidden grid also comes alive.

The update algorithm ( coded in a Timer object ) is started and
stopped by a button.
The code of that button is 'alive = ! alive' and the Timer runs when
alive is true.


For 1 lifecycle we have 4 phases :

>> Phase 1) Prepare the counting of neighbours

Prepare the 2 extra rows and 2 extra columns depending on the wall/wrap
mode.

Wall mode counting neighbours  :
When the application runs in the Wall mode all the extra cells on the
outer side of the hidden grid get the value of being dead.
In the next phase....(So not here)
To count the neigbours of any grid cell we simply check all 8
neighbours of the hidden grid cell right below it if they are alive.
So to count the neigbours of grid cell [0,0] we simply check all 8
neighbours of the hidden grid  cell [1,1] if they are alive.

Wrap mode counting neighbours  :
When the application runs in the Wrap mode all the extra cells on the
outer side of the hidden grid get the value of the opposite side of
the visible grid.
The upper row of the visible grid is copied to the lower of the hidden.
The lower row of the visible grid is copied to the upper of the hidden.
The left  column of the visible is copied to the right of the hidden.
The right column of the visible is copied to the left  of the hidden.
The 4 corners of the visible are copied to the opposite of the hidden.
And again, in the next phase....(So not here)
To count the neigbours of any grid cell we simply check all 8
neighbours of the hidden grid cell right below it if they are alive.
So to count the neigbours of grid cell [0,0] we simply check all 8
neighbours of the hidden grid  cell [1,1] if they are alive.

>> Phase 2) Count Neighbours and update screen grid

To calculate the number of neighbours of each cell in the grid we start
with a situation where the cells in the hidden grid under the visible
grid are filled the same. For life mode the rim of the hidden grid is
dead and for wall mode life was copied from the opposite side

Counting is done in the hidden grid, and during counting we update the
visible grid.
( There are 3 different count versions and 2a is active )
We can not update the hidden grid because this would disrupt the
counting so we have to remember them for the next stage.
To remember I use 2 arrays ld0 for cells which have to be be put to 0
and ld1 for cells which have to be put to 1.

>> Phase 3) Update hidden grid using ld0 and ld1

Phase 2 is a loop construction and when that ends the visible grid shows
the new live situation and now we are ready to update the hidden grid.
2 Simple loops for ld0 and ld1 are used to put some cells to rest and
bring some cells alive in the hidden grid

>>Phase 4) Stop it

We can stop by clicking on the button but we can also stop when there
was nothing to do for phase 3. Life is in a stable state.


To locate sections with details use your editor to search for ****

*/


    // The part of the screen are we using to display life
    property int baseWidth          : parent.width * 0.9
    property int baseHeight         : parent.height * 0.9

    // This application does not support an infinite screen
    property int maxcolumns         : isNxt ? 50 : 36
    property int maxrows            : isNxt ? 50 : 36

    // The number of columns and rows in use with some start value.
    property int columns            : 5
    property int rows               : 5

    // We can change the number of rows and columns above on the preset screen
    property int preset_columns
    property int preset_rows

    // Every cell has this size which updated when any of the parameters change
    property int cellSize           : Math.min(Math.floor(baseHeight / rows), Math.floor(baseWidth / columns))

    // The dimensions of the board ( the grid which is visible on the screen )
    property int boardWidth         : cellSize * columns
    property int boardHeight        : cellSize * rows

    // We have some buttons and want a standard layout
    property int buttonHeight       : isNxt ? 50 : 40
    property int buttonWidth        : baseWidth / 8

    // Some booleans
    property bool alive             : false // should life run ?
    property bool wrapMode          : false // wrap or wall mode ?
    property bool modeClickable     : false // can we toggle cells on screen
    property bool dimState          : false // copied from the Tile dimState

    // Arrays for the hidden grid
    property variant arrayHiddenGrid: []    // life copy to calculate neighbours from
    property variant ld0            : []    // remember what to kill
    property variant ld1            : []    // remember what needs to com e alive

    // The speed can be changed by buttons and we start slow
    property int    speed           : 1     // there are 2 buttons for this

    // This qml contains some screens and buttons change screenMode
    property string screenMode      : "Info" // Info | Life | Preset
    property string prevScreenMode  : ""    // before we started there was no previous screen

    // variables which can be used in the function selectTheme(theme)

    property variant selectThemesData : [ "Black / White", "Red Rings", "Brown", "Lime" ]

    property real heartBeat              : 0

    // Life screen setings

    property int radiusLife                 : 0
    // Live cell
    property string colorLife               : "lightgreen"
    property string borderColorLife         : "lightgreen"
    property int borderWidthLife            : 0
    // Dead not clickable
    property string colorDeadNoClick        : "lightyellow"
    property string borderColorDeadNoClick  : "white"
    property int borderWidthDeadNoClick     : 1
    // Dead clickable
    property string colorDeadClick          : "white"
    property string borderColorDeadClick    : "yellow"
    property int borderWidthDeadClick       : 1

    // dimState settings

    property int radiusDim              : 0
    // Live cell
    property string colorDimLife        : "lightgreen"
    property string borderColorDimLife  : "lightgreen"
    property int borderWidthDimLife     : 0
    // Dead cell
    property string colorDimDead        : "black"
    property string borderColorDimDead  : "black"
    property int borderWidthDimDead     : 0

    // some values to optimize the lifecycle algoritm
    
    // the hidden  grid has 2 more columns
    property int grid2columns : columns + 2
    // when we check 8 neighbours we have 4 corners for which we can precalculate offsets
    property int offsetlt : -1 - (columns + 2)  // lu :: left top neighbour
    property int offsetrt :  1 - (columns + 2)  // ru :: right top neigbour
    property int offsetlb : (columns + 2) - 1   // lb :: left bottom
    property int offsetrb : (columns + 2) + 1   // rb :: right bottom

    property string presetMode      : "resize" // mode for preset screen "resize" or "offset"
    property int presetRowOffset    : 0
    property int presetColumnOffset : 0
    property bool showOffset : true     // There is a timer to make the Offset blink on the preset screen
    
// ********************************************* Compositions and Themes

    property variant jsonLifeData
    property variant lifeExamplesName : []
    property variant lifeThemesName : []

// **************************************************************** Code

    Component.onCompleted: {
        app.log("LifeScreen onCompleted Started")
        getLifeData()
        lifeSetup()
        app.log("LifeScreen onCompleted Completed")
    }

// ---------------------------------------------------------------------

    onVisibleChanged: {
        if ( visible ) {
            debug && app.log("You can see me !   8-)")
            if (prevScreenMode == "" ) { 
                // this is the first time the app starts; set Theme and Example
                selectTheme( 0 )   // color and shape settings
                if (isNxt) { addExample(lifeExamplesName.indexOf("Glider")) }
                else       { addExample(lifeExamplesName.indexOf("Glider")) }                
            }
            getLifeData()   // get the latest Examples and Themes from the Internet
// Trick : We need to know if we are in dimState (hide things, change colors...)
            dimState = app.lifeTile.dimState
        } else { 
            // the screen is hiding and we want it to com back when the app is still running
// Trick : The tile uses app.keepLifeOnScreen to check if it needs to call this screen in dimState
            app.keepLifeOnScreen = alive
            debug && app.log("You can't see me ! |-)")
        }
    }

// ---------------------------------------------------------------------

// ----- Next is handy during debugging of the algorithm in the Timer

    function dumparrayHiddenGrid() {
        app.log("--------------------------------------------------")
        var part = []
        var x = 0
        while (x < (rows+2)*(columns+2) ) {
            part = arrayHiddenGrid.slice(x,x+columns+2)
            app.log("arrayHiddenGrid : "+part)
            x=x+columns + 2
        }
    }

// ---------------------------------------------------------------------

    Timer {
        id: lifeTimer
        interval: isNxt ? 500 * (10 - speed) : 1000 * (10 - speed)
        running: alive
        repeat: true
        onTriggered: {
// we may run into dimState and need the right value
            dimState = app.lifeTile.dimState
// debug is used to show timestamps for all phases of the algorithm
            debug && app.log("------------------------")
// Some variables used below
            let startTime = new Date();
            let nowTime = new Date();

// ************* Setup the outer cells of the hidden grid (Life Phase 1)

            if (wrapMode) {
// 2 outer rows
                for (var c = 1 ; c <= columns ; c ++ ) {
                    arrayHiddenGrid[c] = arrayHiddenGrid[(rows)*(columns+2) + c]
                    arrayHiddenGrid[(rows+1)*(columns+2) + c] = arrayHiddenGrid[columns+2+c]
                }
// 2 outer columns
                for (var r = 1 ; r <= rows ; r ++ ) {
                    arrayHiddenGrid[r*(columns+2)] = arrayHiddenGrid[r*(columns+2)+columns]
                    arrayHiddenGrid[r*(columns+2)+columns+1] = arrayHiddenGrid[r*(columns+2)+1]
                }
// 4 corners
                arrayHiddenGrid[0]                       = arrayHiddenGrid[(rows+1)*(columns+2)-2]
                arrayHiddenGrid[columns+1]               = arrayHiddenGrid[(rows)*(columns+2)+1]
                arrayHiddenGrid[(rows+1)*(columns+2)]    = arrayHiddenGrid[2*(columns+2)-2]
                arrayHiddenGrid[(rows+2)*(columns+2)-1]  = arrayHiddenGrid[columns+3]

            } else { // room mode
// 2 outer rows
                for (var r = 1 ; r < rows+1 ; r ++ ) {
                    arrayHiddenGrid[r*(columns+2)] = 0
                    arrayHiddenGrid[r*(columns+2)+columns+1] = 0
                }
// 2 outer columns
                for (var c = 0 ; c < columns + 2 ; c ++ ) {
                    arrayHiddenGrid[c] = 0
                    arrayHiddenGrid[(rows+1)*(columns+2) + c] = 0
                }
            }

//        dumparrayHiddenGrid()  // this would dump a matrix on the log screen

            nowTime = new Date();
            debug && app.log("Preparing borders             : " + (nowTime-startTime) +" ms" )

// ******* Calculate neighbours, update grid and remember (Life Phase 2)

// ----- Variables used by the algorithms you can choose from below.
// ----- I have 2 algorithms for this. Only one should be active.

            startTime = new Date();

            ld0 = []
            ld1 = []
            var grid2index = 0
            var neighbours = 0
//            var grid2columns = columns + 2
            var columns1 = columns+1
            
            

// **************************************neighbour count algorithms

// ----- uncomment one of the algorithms depending on what you want

/*

// ************************************* neighbour algorithm 1
// looping around each cell and stopping at 4 neighbours 
// because we do not need to count further when we have 4 neighbours

            var rr = 0
            var cc = 0
            for (var r = 1; r<=rows ; r++ ) {
                for (var c = 1 ; c<=columns; c++) {
                    grid2index= r * grid2columns + c
                    rr = -1
                    neighbours = 0
                    while ( (rr < 2 ) && ( neighbours < 4) ) {
                        cc = -1
                        while ( (cc < 2 ) && ( neighbours < 4)  ) {
                                if ( ! ( (rr == 0) && (cc == 0) ) ) { neighbours += arrayHiddenGrid[grid2index + rr*grid2columns + cc] }
                            cc++
                        }
                        rr++
                    }

                    if (arrayHiddenGrid[grid2index] == 0 ) {
                        if ( neighbours == 3 ) {
                            ld1.push(grid2index)
// the next two lines are there to explain how I got to the third line below
//                            lifeModel.setProperty((r-1) * columns + c - 1, "lifeState", true)
//                            lifeModel.setProperty(r * columns - (columns + 1) + c , "lifeState", true)
                            lifeModel.setProperty(r * columns - columns1 + c , "lifeState", true)
                       }
                    } else if ( ( neighbours != 2 ) && ( neighbours != 3 ) ) {
//                    } else if ( ! ( ( neighbours == 2 ) || ( neighbours == 3 ) ) ) {
                            ld0.push(grid2index)
// the next two lines are there to explain how I got to the third line below
//                            lifeModel.setProperty((r-1) * columns + c - 1, "lifeState", false)
//                            lifeModel.setProperty(r * columns - (columns + 1) + c , "lifeState", false)
                            lifeModel.setProperty(r * columns - columns1 + c , "lifeState", false)
                     }
                }
            }

*/




/*

// ************************************* neighbour algorithm 2
// not looping around cell but simply adding all cells in one statement
// avoiding 2 more loops

            for (var r = 1; r<=rows ; r++ ) {
                for (var c = 1 ; c<=columns; c++) {
                    grid2index= r * grid2columns + c

// to get the neighbours, we add all the 1's around this grid2index

                    neighbours=arrayHiddenGrid[grid2index - grid2columns - 1] + arrayHiddenGrid[grid2index - grid2columns] + arrayHiddenGrid[grid2index - grid2columns + 1]
                             + arrayHiddenGrid[grid2index - 1]                                                            + arrayHiddenGrid[grid2index + 1]
                             + arrayHiddenGrid[grid2index + grid2columns - 1] + arrayHiddenGrid[grid2index + grid2columns] + arrayHiddenGrid[grid2index + grid2columns + 1]

                    if (arrayHiddenGrid[grid2index] == 0 ) {
                        if ( neighbours == 3 ) {
                            ld1.push(grid2index)
// the next two lines are there to explain how I got to the third line below
//                            lifeModel.setProperty((r-1) * columns + c - 1, "lifeState", true)
//                            lifeModel.setProperty(r * columns - (columns + 1) + c , "lifeState", true)
                            lifeModel.setProperty(r * columns - columns1 + c , "lifeState", true)
                       }
                    } else if ( ( neighbours != 2 ) && ( neighbours != 3 ) ) {
                            ld0.push(grid2index)
// the next two lines are there to explain how I got to the third line below
//                            lifeModel.setProperty((r-1) * columns + c - 1, "lifeState", false)
//                            lifeModel.setProperty(r * columns - (columns + 1) + c , "lifeState", false)
                            lifeModel.setProperty(r * columns - columns1 + c , "lifeState", false)
                     }
                }
            }
*/

/*

// ************************************* neighbour algorithm 2a
// like 2 not looping around cell but simply adding all cells in one statement
// avoiding 2 more loops
// Plus : use precalculated offsets for corners so there is a little less calculation

            for (var r = 1; r<=rows ; r++ ) {
                for (var c = 1 ; c<=columns; c++) {
                    grid2index= r * grid2columns + c

// The next from algorithm 2
//                    neighbours=arrayHiddenGrid[grid2index - grid2columns - 1] + arrayHiddenGrid[grid2index - grid2columns] + arrayHiddenGrid[grid2index - grid2columns + 1]
//                             + arrayHiddenGrid[grid2index - 1]                                                            + arrayHiddenGrid[grid2index + 1]
//                             + arrayHiddenGrid[grid2index + grid2columns - 1] + arrayHiddenGrid[grid2index + grid2columns] + arrayHiddenGrid[grid2index + grid2columns + 1]
// changed to this to get algoritm 2a

                    neighbours=arrayHiddenGrid[grid2index + offsetlt] + arrayHiddenGrid[grid2index - grid2columns] + arrayHiddenGrid[grid2index + offsetrt]
                             + arrayHiddenGrid[grid2index - 1]                                                            + arrayHiddenGrid[grid2index + 1]
                             + arrayHiddenGrid[grid2index + offsetlb] + arrayHiddenGrid[grid2index + grid2columns] + arrayHiddenGrid[grid2index + offsetrb]

                    if (arrayHiddenGrid[grid2index] == 0 ) {
                        if ( neighbours == 3 ) {
                            ld1.push(grid2index)
// the next two lines are there to explain how I got to the third line below
//                            lifeModel.setProperty((r-1) * columns + c - 1, "lifeState", true)
//                            lifeModel.setProperty(r * columns - (columns + 1) + c , "lifeState", true)
                            lifeModel.setProperty(r * columns - columns1 + c , "lifeState", true)
                       }
                    } else if ( ( neighbours != 2 ) && ( neighbours != 3 ) ) {
                            ld0.push(grid2index)
// the next two lines are there to explain how I got to the third line below
//                            lifeModel.setProperty((r-1) * columns + c - 1, "lifeState", false)
//                            lifeModel.setProperty(r * columns - (columns + 1) + c , "lifeState", false)
                            lifeModel.setProperty(r * columns - columns1 + c , "lifeState", false)
                     }
                }
            }
*/

// ************************************* neighbour algorithm 3

// using some techniques from above Plus : https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life#Algorithms
//
// To avoid decisions and branches in the counting loop, the rules can be rearranged from an egocentric 
// approach of the inner field regarding its neighbours to a scientific observer's viewpoint: 
// if the sum of all nine fields in a given neighbourhood is three, 
// the inner field state for the next generation will be life; 
// if the all-field sum is four, the inner field retains its current state; 
// and every other sum sets the inner field to death. 
//
            var neighbourhood = 0

            for (var r = 1; r<=rows ; r++ ) {
                for (var c = 1 ; c<=columns; c++) {
                    grid2index= r * grid2columns + c

                    neighbourhood=arrayHiddenGrid[grid2index + offsetlt] + arrayHiddenGrid[grid2index - grid2columns] + arrayHiddenGrid[grid2index + offsetrt]
                                + arrayHiddenGrid[grid2index - 1]        + arrayHiddenGrid[grid2index ]               + arrayHiddenGrid[grid2index + 1]
                                + arrayHiddenGrid[grid2index + offsetlb] + arrayHiddenGrid[grid2index + grid2columns] + arrayHiddenGrid[grid2index + offsetrb]

                    if (neighbourhood == 3) {     
                        if (arrayHiddenGrid[grid2index] != 1 ) {
                            lifeModel.setProperty(r * columns - columns1 + c , "lifeState", true)
                            ld1.push(grid2index)
                        }
                    } else { 
                        if (arrayHiddenGrid[grid2index] != 0 ) {
                            if ( neighbourhood != 4 ) {
                                lifeModel.setProperty(r * columns - columns1 + c , "lifeState", false)
                                ld0.push(grid2index)
                            }
                        }
                    }
                }
            }

// ----- end of algorithms

// ----- report progress

            nowTime = new Date();
            debug && app.log("Neighbours, ld0, ld1 and grid : " + (nowTime-startTime) +" ms")
//            app.log("Prep ld0 : "+ld0)
//            app.log("Prep ld1 : "+ld1)


// ******************************* Update the hidden grid (Life Phase 3)

            startTime = new Date();

            for (var ld0index = 0 ; ld0index < ld0.length ; ld0index++) {
                arrayHiddenGrid[ld0[ld0index]] = 0
            }
            for (var ld1index = 0 ; ld1index < ld1.length ; ld1index++) {
                arrayHiddenGrid[ld1[ld1index]] = 1
            }

// ******************************** Stop or go on looping (Life Phase 4)

            alive = ( ( ld0.length > 0) || ( ld1.length > 0) )

//            alive = false     // I use this for testing when I want to step through lifecycles

            nowTime = new Date();
            debug && app.log("Updating arrayHiddenGrid      : " + (nowTime-startTime) + " ms        ; #cells : "+ (ld0.length +ld1.length) )
            
            if (!alive) {dimState = false}

        }
    }

// ***************************************************** Setup functions
    function getLifeData() {

        var url="https://raw.githubusercontent.com/JackV2020/appData/main/lifeData/lifeData.json"
        
        if (useTestData) { url="https://raw.githubusercontent.com/JackV2020/appDataTest/main/lifeData/lifeData.json" }

        if (useJacksData) { url="http://veraart.thehomeserver.net:8888/lifeData.json" }

        var xmlhttpLifeExamples = new XMLHttpRequest();

        xmlhttpLifeExamples.open("GET", url, true);

        xmlhttpLifeExamples.onreadystatechange = function() {

            if (xmlhttpLifeExamples.readyState == XMLHttpRequest.DONE) {

                if (xmlhttpLifeExamples.status === 200) {

                    jsonLifeData = JSON.parse(xmlhttpLifeExamples.response);

                    lifeExamplesName=[]
                    var i = 0
                    var oke=true
                    while(oke) {
                        try {
                            if (isNxt) {
                                lifeExamplesName.push(jsonLifeData.lifeExamples[i]['Name'])
                            } else {
                                if (jsonLifeData.lifeExamples[i]['Type'] == "T1") { // Toon1 : T1 only
                                    lifeExamplesName.push(jsonLifeData.lifeExamples[i]['Name'])
                                }
                            }
                            i++
                        } catch(e) {
                            oke = false
                            debug && app.log("getLifeData : url : "+url)
                            debug && app.log("getLifeData : lifeExamples count : "+lifeExamplesName.length)
                        }
                    }

                    lifeThemesName=[]
                    i = 0
                    oke=true
                    while(oke) {
                        try {
                            lifeThemesName.push(jsonLifeData.lifeThemes[i]['Name'])
                            i++
                        } catch(e) {
                            oke = false
                            debug && app.log("getLifeData : lifeThemes count : "+lifeThemesName.length)
                        }
                    }
                } else {

                   app.log(url +" Return status: " + xmlhttpLifeExamples.status)

                }
            }
        }

        xmlhttpLifeExamples.send();
    
    }

// ---------------------------------------------------------------------

// Data for the GridView is stored in a model which is a long list like
// an array which fills the grid row by row and starts in the upper left
// corner.
// Data for the hidden grid is stored in an array which has 2 more rows
// and 2 more columns than the GridView

    function lifeSetup() {
        for (var i = 0 ; i < maxcolumns * maxrows ; i++ ){
            lifeModel.append({id: i , lifeState : false})
            arrayHiddenGrid.push(0)
        }
// Add the 2 extra rows and columns to the hidden array
        for (var i = 0 ; i < (maxcolumns*2) + (maxrows*2) + 4 ; i++ ){
            arrayHiddenGrid.push(0)
        }
    }

// ---------------------------------------------------------------------

    function resetBoard_new() {
// This would be what I want but is veeeerrryy slooooooowwww......

        // remove delegates from model when needed
        var i = lifeModel.count - 1
        while( rows * columns - 1 < i  ) {  
            lifeModel.remove(i)
            i = i - 1
        }

        // add delegates to model when needed
        // i is index last entry
        while( rows * columns > lifeModel.count) {  // add delegates to model
            i++
            lifeModel.append({id: i , lifeState : false})
        }

        // clear model 
        for( var i = 0 ; i < (rows*columns) ; i++ ) {
            lifeModel.setProperty(i , "lifeState", false)
        }

        // clear hidden array
        for (var i = 0 ; i < (maxcolumns*2) * (maxrows*2) ; i++ ){
            arrayHiddenGrid[i]=0
        }
    }

// ---------------------------------------------------------------------

    function resetBoard() {

        // clear model
        for( var i = 0 ; i < (maxcolumns*maxrows) ; i++ ) {
            lifeModel.setProperty(i , "lifeState", false)
        }

        // clear hidden array
        for (var i = 0 ; i < (maxcolumns*2) * (maxrows*2) ; i++ ){
            arrayHiddenGrid[i]=0
        }
    }

// ---------------------------------------------------------------------

    function toggleCell(row , col) {
        var gridindex=row * columns + col
        var grid2index=(row+1) * (columns + 2) + ( col + 1 )
        if ( lifeModel.get(gridindex).lifeState ) {
            lifeModel.setProperty(gridindex, "lifeState", false)
            arrayHiddenGrid[grid2index] = 0
        } else  {
            lifeModel.setProperty(gridindex, "lifeState", true)
            arrayHiddenGrid[grid2index] = 1
        }
    }

// ---------------------------------------------------------------------

// ----- Next is called from a button on the screen to spread some life
// ----- Also implemented as an option in the menu so called by a case in addExample

    function randomLife() {
        let ammount = 0.05   // ammount < 1 and ammount > 0
        for ( var i = 1 ; i < Math.floor(rows * columns * ammount ) ; i++ ) {
            toggleCell(Math.floor(Math.random() * rows ), Math.floor(Math.random() * columns))
        }
    }

// ***************************************************** Themes function

// Some themes have a heartbeat setting in it

    property int activeTheme : 0
    
    Timer {
        id: heartBeatTimer
        interval: dimState ? Math.floor(10000 * heartBeat) : Math.floor(1000 * heartBeat)
        running: alive && (heartBeat > 0 )
        repeat: true
        onTriggered: {
            app.log("heartBeatTimer "+interval)
            if (borderWidthLife == cellSize)
            {   borderWidthLife    = eval(jsonLifeData.lifeThemes[activeTheme]['borderWidthLife'])
                borderWidthDimLife = eval(jsonLifeData.lifeThemes[activeTheme]['borderWidthDimLife'])  }
            else { borderWidthLife = cellSize     ; borderWidthDimLife = cellSize }
        }
    }

// ---------------------------------------------------------------------

    function selectTheme(theme) {
//      eval(jsonLifeData.lifeThemes[itemSelected]['radiusLife'])

        activeTheme = theme

        try      {                   heartBeat = eval(jsonLifeData.lifeThemes[activeTheme]['heartBeat']) }
        catch(e) { activeTheme = 0 ; heartBeat = eval(jsonLifeData.lifeThemes[activeTheme]['heartBeat']) }
    // Life screen setings
         radiusLife              = eval("Math.floor("+jsonLifeData.lifeThemes[activeTheme]['radiusLife']+")")
    // Live cell
         colorLife               = jsonLifeData.lifeThemes[activeTheme]['colorLife']
         borderColorLife         = jsonLifeData.lifeThemes[activeTheme]['borderColorLife']
         borderWidthLife         = eval("Math.floor("+jsonLifeData.lifeThemes[activeTheme]['borderWidthLife']+")")
    // Dead not clickable
         colorDeadNoClick        = jsonLifeData.lifeThemes[activeTheme]['colorDeadNoClick']
         borderColorDeadNoClick  = jsonLifeData.lifeThemes[activeTheme]['borderColorDeadNoClick']
         borderWidthDeadNoClick  = eval("Math.floor("+jsonLifeData.lifeThemes[activeTheme]['borderWidthDeadNoClick']+")")
    // Dead clickable
         colorDeadClick          = jsonLifeData.lifeThemes[activeTheme]['colorDeadClick']
         borderColorDeadClick    = jsonLifeData.lifeThemes[activeTheme]['borderColorDeadClick']
         borderWidthDeadClick    = eval("Math.floor("+jsonLifeData.lifeThemes[activeTheme]['borderWidthDeadClick']+")")

    // dimState settings
         radiusDim              = eval("Math.floor("+jsonLifeData.lifeThemes[activeTheme]['radiusDim']+")")
    // Live cell
         colorDimLife           = jsonLifeData.lifeThemes[activeTheme]['colorDimLife']
         borderColorDimLife     = jsonLifeData.lifeThemes[activeTheme]['borderColorDimLife']
         borderWidthDimLife     = eval("Math.floor("+jsonLifeData.lifeThemes[activeTheme]['borderWidthDimLife']+")")
    // Dead cell
         colorDimDead           = jsonLifeData.lifeThemes[activeTheme]['colorDimDead']
         borderColorDimDead     = jsonLifeData.lifeThemes[activeTheme]['borderColorDimDead']
         borderWidthDimDead     = eval("Math.floor("+jsonLifeData.lifeThemes[activeTheme]['borderWidthDimDead']+")")

    }

// ---------------------------------------------------------------------

// **************************************************** Preset functions

// Make the Offset cell blink

    Timer {
        id: offsetTimer
        interval: 1000
        running: (screenMode == "Preset" )
        repeat: true
        onTriggered: { showOffset = ! showOffset }
    }

// ---------------------------------------------------------------------

    function togglePreset(row,col,rowOrientation,colOrientation,dots) {
/*

   This function is used to add/remove a complete composition on the screen.
  
    rows are numbered from top to bottom, columns from left to right
  
   columns 0 1 2 3 ..
    rows 0
         1
         2
         3
         :
  
    row, col  : position for the origin row and column of the preset
                2,4 means 3rd row, 5th column because count starts at 0
  
    dots      : array of points of Preset like :
               [ [0,1] , [1,2] , [2,0] , [2,1] , [2,2] ]
  
            the . in the text below point at the origin
                    .1                     .#
          order >     2     result >         #
                    345                    ###
  
    The next 2 allow the composition to be be rotated on the screen :
  
    rowOrientation    : 1 build down  ; -1 build up
    colOrientation    : 1 build right ; -1 build left
  
*/
        for (var i = 0 ; i < dots.length ; i ++) {
            toggleCell((row+rowOrientation*dots[i][0]),
                       (col+colOrientation*dots[i][1]))
        }
    }

// ---------------------------------------------------------------------

    function minRowsCols(minrows,mincols) {
// Can be used to force screen size
        if ((rows < minrows) || (columns<mincols) ) {
            rows=minrows
            columns=mincols
            preset_rows=minrows
            preset_columns=mincols
            resetBoard()
        }
    }
// ---------------------------------------------------------------------

    function setRowsCols(minrows,mincols) {
// Can be used to force screen size
        if ((rows != minrows) || (columns != mincols) ) {
            rows=minrows
            columns=mincols
            preset_rows=minrows
            preset_columns=mincols
            resetBoard()
        }
    }

// ---------------------------------------------------------------------

    function addExample(itemSelected) {

        if (lifeExamplesName[itemSelected] == "Random") {
            randomLife()
        } else{
            if (typeof jsonLifeData.lifeExamples[itemSelected]['WrapMode'] !== "undefined" )
                { wrapMode = jsonLifeData.lifeExamples[itemSelected]['WrapMode'] }
            if (typeof jsonLifeData.lifeExamples[itemSelected]['MinRowsCols'] !== "undefined" )
                { minRowsCols(jsonLifeData.lifeExamples[itemSelected]['MinRowsCols'][0],jsonLifeData.lifeExamples[itemSelected]['MinRowsCols'][1]) }
            if (typeof jsonLifeData.lifeExamples[itemSelected]['SetRowsCols'] !== "undefined" )
                { setRowsCols(jsonLifeData.lifeExamples[itemSelected]['SetRowsCols'][0],jsonLifeData.lifeExamples[itemSelected]['SetRowsCols'][1]) }
            if (typeof jsonLifeData.lifeExamples[itemSelected]['Speed'] !== "undefined" ) { speed = jsonLifeData.lifeExamples[itemSelected]['Speed'] }
            var i = 0
            var oke = true
            while(oke) {
                try {
                        togglePreset(
                            jsonLifeData.lifeExamples[itemSelected]['Positioning'][i][0]+presetRowOffset,
                            jsonLifeData.lifeExamples[itemSelected]['Positioning'][i][1]+presetColumnOffset,
                            jsonLifeData.lifeExamples[itemSelected]['Positioning'][i][2],
                            jsonLifeData.lifeExamples[itemSelected]['Positioning'][i][3],
                            jsonLifeData.lifeExamples[itemSelected]['Array']
                        )                        
                        i++
                    }
                catch(e) { 
                        oke = false ; 
                    }
            }
        }
    }
    
// ---------------------------------------------------------------------

// *************************************************** Cover Home Button

	Rectangle {
        id                      : coverHomeButton
        width                   : 2000
        height                  : 2000
		color                   : dimState ? "black" : colors.canvas
        anchors {
            verticalCenter      : parent.verticalCenter
        }
        visible                 : ( ( screenMode != "Life" ) || alive )
    }

// ********************************************************* Info Screen

// This Info screen is shown as first after a GUI restart / reboot
// This Info screen is also available as a button on the Preset screen

    Rectangle {
        id                      : infoScreen
        visible                 : ( screenMode == "Info" )
        width                   : baseWidth
        height                  : baseHeight
		color                   : colors.canvas
        border.width            : 0
        anchors {
            top                 : parent.top
            horizontalCenter    : parent.horizontalCenter
        }

        Text {
            id                      : infoText
            width                   : parent.width
            wrapMode                : Text.WordWrap
            horizontalAlignment     : Text.AlignHCenter
            anchors {
                top                 : parent.top
                horizontalCenter    : parent.horizontalCenter
            }
            lineHeight: 0.8
            font    {
                pixelSize           : isNxt ? 20 : 16
                family              : qfont.regular.name
                bold                : false
            }
            text:
            "Conway's game of life"
            +"\n\nFor a full description see : https://en.m.wikipedia.org/wiki/Conway's_Game_of_Life"
            +"\n\nIn short Life is a zero player game on a 2 dimensional plane with 3 rules :"
            +"\n\n1) Any live cell with two or three live neighbours survives."
            +  "\n2) Any dead cell with three live neighbours becomes a live cell."
            +  "\n3) All other live cells die in the next generation. Similarly, all other dead cells stay dead."
            +"\n\nThis implementation has no plane but uses either a room with walls or a wrap mode where the opposite sides and all 4 corners are connected."
            +  "\nThis causes live organisms to collide into the walls or to 'travel' to the other side of the board."

            + "\n\nThe inital setup of the app is an example from the Presets page."
            +   "\nAll you need to do is click \"Start Life\" and increase the Speed." 

            + "\n\nThe Presets page has examples and the Life page uses themes which come directly a github repository."
            + " When you want see that, or better contribute, see lifeData in :"
            + "\nhttps://github.com/JackV2020/appDataTest"

        }

        YaLabel {
            id                  : toggleuseTestData
            buttonText          : useTestData ? "Using Test Data" : ""
            width               : buttonWidth
            height              : buttonHeight
            hoveringEnabled     : false

            buttonActiveColor   : "transparent"
            buttonHoverColor    : "transparent"
            buttonSelectedColor : "transparent"
            buttonBorderWidth   : 0
            anchors {
                top             : parent.top
                left            : parent.left
            }
            onClicked           : { useJacksData = false ; useTestData = ! useTestData ; getLifeData() }
        }

        YaLabel {
            id                  : toggleuseJacksData
            buttonText          : useJacksData ? "Using Jacks Data" : ""
            width               : buttonWidth
            height              : buttonHeight
            hoveringEnabled     : false

            buttonActiveColor   : "transparent"
            buttonHoverColor    : "transparent"
            buttonSelectedColor : "transparent"
            buttonBorderWidth   : 0
            anchors {
                top             : parent.top
                right           : parent.right
            }
            onClicked           : { useTestData = false ; useJacksData =! useJacksData ; getLifeData() }
        }

        YaLabel {
            id                  : leaveInfoScreenButton
            buttonText          : "To App"
            width               : buttonWidth
            height              : buttonHeight
            hoveringEnabled     : isNxt
            anchors {
                top             : parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            onClicked           : { if ( prevScreenMode == "" ) { screenMode = "Life" ; prevScreenMode = "Info" } else { screenMode = prevScreenMode } }
        }

    }

// ******************************************************** Life Buttons

// A title for the screen

    YaLabel {
        visible             : ( screenMode == "Life" ) && (! dimState )
        buttonText          : alive ? "It's alive !! , let's wait for the screen to dim...." : "Game of Life"
        width               : alive ? buttonWidth * 4 : buttonWidth * 2
        height              : buttonHeight
        hoveringEnabled     : false
        buttonActiveColor   : colors.canvas
        buttonSelectedColor : colors.canvas
        buttonHoverColor    : colors.canvas
        anchors {
            top             : parent.top
            topMargin       : buttonHeight * -1
            horizontalCenter: parent.horizontalCenter
        }
    }

    ScrollMenu {
        id                  : selectThemeMenu
        visible             : ( screenMode == "Life" ) && (! dimState) // hide buttons in dimstate
        buttonText          : "Select Theme"
        scrollmenuArray     : lifeThemesName
        autoHideScrollMenuSeconds : 5
        showItems           : 4
        anchors {
            top             : parent.top
            right           : boardButtons.right
            topMargin       : buttonHeight * -1
        }
        fontFamily          : qfont.regular.name
        buttonPixelSize     : isNxt ? 20 : 16
        itemPixelSize       : isNxt ? 20 : 16
        onItemSelected      : { selectTheme(selectedItemIndex) }
    }

	Rectangle {
        visible             : ( screenMode == "Life" ) && (! dimState) // hide buttons in dimstate
        id                  : boardButtons
        width               : baseWidth
        height              : buttonHeight
		color               : ( prevScreenMode == "" ) ? colors.canvas : dimState ? "black" : colors.canvas
        anchors {
            bottom          : parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        YaLabel {
            id              : resetButton
            enabled         : (! alive)
            buttonText      : "Clear"
            width           : buttonWidth
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                right       : lifeButton.left
            }
            onClicked       : { resetBoard()  }

        }

        YaLabel {
            id              : lifeButton
            buttonText      : alive ? "Pause Life" : "Start Life"
            width           : buttonWidth
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                right       : wrapModeButton.left
            }
            onClicked       : { alive = ! alive }
        }

        YaLabel {
            id              : wrapModeButton
            enabled         : ! alive
            buttonText      : wrapMode ? "Wrap" : "Room"
            width           : buttonWidth
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                right       : lifeSpeedMin.left
            }
            onClicked       : { wrapMode = ! wrapMode }
        }

        YaLabel {
            id              : lifeSpeedMin
            buttonText      : "Speed -"
            width           : buttonWidth * 7 / 8
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                right       : lifeSpeed.left
            }
            onClicked       : { if ( speed > 1 ) { speed = speed - 1 } }
        }

        YaLabel {
            id              : lifeSpeed
            buttonText      : speed
            width           : buttonWidth / 4
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                horizontalCenter : parent.horizontalCenter
            }
        }

        YaLabel {
            id              : lifeSpeedplus
            buttonText      : "Speed +"
            width           : buttonWidth * 7 / 8
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                left        : lifeSpeed.right
            }
            onClicked       : { if ( speed < 9 ) { speed = speed + 1 } }
        }

        YaLabel {
            id              : lifeModeButton
            buttonText      : "No clicks"
            buttonText2     : "Click cells"
            buttonText2Stack: true
            buttonText2Swap : true
            width           : buttonWidth
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                left        : lifeSpeedplus.right
            }
            onClicked       : { selected = ! selected ; modeClickable = ! modeClickable }
        }

        YaLabel {
            id              : lifeRandom
            enabled         : modeClickable
            buttonText      : "Random"
            width           : buttonWidth
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                left        : lifeModeButton.right
            }
            onClicked       : { randomLife() }
        }

        YaLabel {
            id              : presetsScreenButton
            enabled         : (! alive)
            buttonText      : "Presets"
            width           : buttonWidth
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                left        : lifeRandom.right
            }
            onClicked       : {
                prevScreenMode = screenMode
                screenMode = "Preset"
                preset_columns = columns
                preset_rows = rows
            }
        }

    }

// ********************************************************** Life Board

// This is the life GridView as shown on the main app screen

// The board which we see on the screen

	Rectangle {
        id                  : boardRim
        visible             : ( screenMode == "Life" )
        width               : (wrapMode) ? (boardWidth + 2) : (boardWidth + 6)
        height              : (wrapMode) ? (boardHeight +2) : (boardHeight +6)
		color               : dimState ? "black" : colors.canvas
        border {
            width           : (wrapMode) ? 1 : 3
            color           : "black"
        }
        anchors {
            bottom          : boardButtons.top
            bottomMargin    : (wrapMode) ? 4 : 2
            horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            id                  : board
            visible             : ( screenMode == "Life" )
            width               : boardWidth
            height              : boardHeight
            color               : dimState ? "black" : colors.canvas
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }

            ListModel {
                id              : lifeModel
            }

            GridView {
                id              : lifeGrid
                anchors.fill    : parent
                cellWidth       : cellSize
                cellHeight      : cellSize
                model           : lifeModel
                
                interactive: false

                delegate:
                Rectangle {
                    enabled     : ( modeClickable )
                    width       : cellSize
                    height      : cellSize
                    radius      : dimState ? radiusDim : radiusLife
                    color       : dimState ? model.lifeState ? colorDimLife
                                                             : colorDimDead
                                           : model.lifeState ? colorLife
                                                             : modeClickable ? colorDeadClick
                                                                             : colorDeadNoClick
                    border {
                        width   : dimState ? model.lifeState ? borderWidthDimLife
                                                             : borderWidthDimDead
                                           : model.lifeState ? borderWidthLife
                                                             : modeClickable ? borderWidthDeadClick
                                                                             : borderWidthDeadNoClick

                        color   : dimState ? model.lifeState ? borderColorDimLife
                                                             : borderColorDimDead
                                           : model.lifeState ? borderColorLife
                                                             : modeClickable ? borderColorDeadClick
                                                                             : borderColorDeadNoClick
                    }

                    MouseArea {
                        anchors.fill    : parent
                        onClicked       : { toggleCell(Math.floor(index / columns),(index%columns)) }
                    }

                    visible     : (index < columns * rows )

                }
            }
        }

    }
// ************************ Presets Screen Mini Board + Text + Selection

    Rectangle {
        id                  : presetsScreen
        visible             : ( screenMode == "Preset" )
        width               : baseWidth
        height              : baseHeight
		color               : colors.canvas
        border.width        : 1
        anchors {
            top             : parent.top
            horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            id              : miniboardFrame
            width           : ( isNxt ? 6 : 5 ) * maxcolumns + 4
            height          : ( isNxt ? 6 : 5 ) * maxrows + 4
            color           : colors.canvas
            border.width    : 2
            anchors {
                bottom      : presetColumnsText.top
                left        : presetRowText.right
                leftMargin  : 2
                bottomMargin: 2
            }
        }

        Rectangle {
            id                  : miniboard
            width               : ( isNxt ? 6 : 5 ) * columns
            height              : ( isNxt ? 6 : 5 ) * rows
            color               : "lightyellow"
            anchors {
                horizontalCenter: miniboardFrame.horizontalCenter
                verticalCenter  : miniboardFrame.verticalCenter
            }

            GridView {
                id              : minilifeGrid
                enabled         : (screenMode == "Preset")
                anchors.fill    : parent
                cellWidth       : isNxt ? 6 : 5
                cellHeight      : isNxt ? 6 : 5
                model           : lifeModel

                interactive     : false

                delegate:
                Rectangle {
                    width       : isNxt ? 6 : 5
                    height      : isNxt ? 6 : 5
                    color       : ( (index == presetRowOffset * columns + presetColumnOffset) && showOffset ) ? "red" : "green"
                    visible     : model.lifeState || (index == presetRowOffset * columns + presetColumnOffset) // && (index < columns * rows )
                }
            }
        }

        ScrollMenu {
            id                  : selectLife
            buttonText          : "Life Examples"
            scrollmenuArray     : lifeExamplesName
            cellNumberPrefix    : true
            showItems           : isNxt ? 6 : 5
            anchors {
                top             : parent.top
                horizontalCenter: presetScreenText.horizontalCenter
                topMargin       : buttonHeight
            }
            fontFamily          : qfont.regular.name
            buttonPixelSize     : isNxt ? 20 : 16
            itemPixelSize       : isNxt ? 20 : 16
            onItemSelected      : { addExample(selectedItemIndex) }
        }

        Text {
            id                  : presetScreenText
            width               : parent.width / 2
            height              : parent.height / 2
            wrapMode            : Text.WordWrap
            horizontalAlignment : Text.AlignHCenter

            anchors {
                top             : selectLife.bottom
                right           : parent.right
                topMargin       : buttonHeight / 2
            }
            font    {
                pixelSize       : isNxt ? 20 : 16
                family          : qfont.regular.name
                bold            : false
            }
            text:
             "The examples need a minimum or a fixed size.\nClick and wait....."
        +   "\nEach may clear and resize the board.\nResizing takes time....."
        +   "\nClick the same again to remove the selection."
        +   "\n\nOn the left you can change Size and Offset."
        +   "\n\nThe bigger the board, the more the work, the slower the app....."
        +   "\n.....even buttons may react slower....."
        }

// ***************************************** Presets Screen Size Buttons

        YaLabel {
            id              : x3x3
            buttonText      : "3 x 3"
            width           : buttonWidth
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                top         : meanxmean.top
                right       : meanxmean.left
                rightMargin : 2
            }
            onClicked       : { rows = 3; columns = 3 ; preset_rows = 3 ; preset_columns = 3 ; resetBoard() }
        }

        YaLabel {
            id              : meanxmean
            buttonText      : Math.floor(maxrows/2) +" x " + Math.floor(maxcolumns/2)
            width           : buttonWidth
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom          : miniboardFrame.top
                horizontalCenter: miniboardFrame.horizontalCenter
                bottomMargin    : 2
            }
            onClicked       : { rows = Math.floor(maxrows/2); columns = Math.floor(maxcolumns/2) ; preset_rows = rows ; preset_columns = columns ; resetBoard() }
        }

        YaLabel {
            id              : maxxmax
            buttonText      : maxrows +" x " + maxcolumns
            width           : buttonWidth
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                top         : meanxmean.top
                left        : meanxmean.right
                leftMargin  : 2
            }
            onClicked       : { rows = maxrows; columns = maxcolumns ; preset_rows = rows ; preset_columns = columns ; resetBoard() }
        }

        YaLabel {
            id              : presetModeButton
            buttonText      : "Size"
            buttonText2     : "Offset"
            buttonText2Stack: true
            buttonText2Swap : true
            width           : buttonWidth
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom      : resetButton2.bottom
                right       : resetButton2.left
                rightMargin : 2
            }
            onClicked       : { if (presetMode == "resize") { presetMode = "offset"} else {presetMode = "resize"} ; selected = ! selected }
        }

        YaLabel {
            id              : resetButton2
            buttonText      : "Clear"
            width           : buttonWidth
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                left        : meanxmean.left
                bottom      : meanxmean.top
                bottomMargin: 2
            }
            onClicked       : { preset_columns = columns ; preset_rows = rows ; presetRowOffset=0 ; presetColumnOffset=0; resetBoard() }
        }

        YaLabel {
            id              : applyLayout
            visible         : ! isNxt
            enabled         : ( (preset_columns != columns ) || ( preset_rows !=rows ) ) && (presetMode == "resize")
            buttonText      : "Apply Size"
            width           : buttonWidth
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom      : resetButton2.bottom
                left        : resetButton2.right
                leftMargin  : 2
            }
            onClicked       : { columns = preset_columns ; rows = preset_rows ; resetBoard() }
        }

        YaLabel {
            id              : rowsPlus
            enabled         : ( ( presetMode == "resize" ) && (preset_rows <maxrows) ) || ( ( presetMode == "offset" ) && (presetRowOffset > 0) )
            buttonText      : (presetMode == "resize" ) ? "+" : "^"
            width           : buttonHeight
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom      : presetRowText.top
                left        : presetRowText.left
            }
            onClicked       : { 
                if (presetMode == "resize" ) {
                    preset_rows++ ; if ( isNxt ) { rows = preset_rows ; resetBoard() } 
                } else {
                    presetRowOffset--
                }
            }
        }

        YaLabel {
            id              : presetRowText
            buttonText      : (presetMode == "resize" ) ? preset_rows : presetRowOffset
            width           : buttonHeight
            height          : buttonHeight
            buttonBorderWidth   : 0
            buttonActiveColor   : colors.canvas
            buttonHoverColor    : buttonActiveColor
            buttonSelectedColor : buttonActiveColor
            hoveringEnabled : false
            anchors {
                verticalCenter  : miniboardFrame.verticalCenter
                left            : parent.left
                leftMargin      : 2
                rightMargin     : 2
            }
        }

        YaLabel {
            id              : rowsMinus
            enabled         : ( ( presetMode == "resize" ) && (preset_rows >3 ) ) || ( ( presetMode == "offset" ) && (presetRowOffset < rows - 1) )
            buttonText      : (presetMode == "resize" ) ? "-" : "v"
            width           : buttonHeight
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                top         : presetRowText.bottom
                left        : presetRowText.left
            }
            onClicked       : { 
                if (presetMode == "resize" ) {
                    preset_rows-- ;
                    if ( presetRowOffset > preset_rows - 1) {presetRowOffset--}
                    if ( isNxt ) { rows = preset_rows ; resetBoard() } 
                } else {
                    presetRowOffset++
                }
            }
        }

        YaLabel {
            id              : columnsMinus
            enabled         : ( ( presetMode == "resize" ) && (preset_columns >3 ) ) || ( ( presetMode == "offset" ) && (presetColumnOffset > 0) )
            buttonText      : (presetMode == "resize" ) ? "-" : "<"
            width           : buttonHeight
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom      : presetColumnsText.bottom
                right       : presetColumnsText.left
            }
            onClicked       : { 
                if (presetMode == "resize" ) {
                    preset_columns--
                    if ( presetColumnOffset > preset_columns - 1) {presetColumnOffset--}
                    if ( isNxt ) { columns = preset_columns ; resetBoard() }
                } else {
                    presetColumnOffset--
                }
            }
        }

        YaLabel {
            id              : presetColumnsText
            buttonText      : (presetMode == "resize" ) ? preset_columns : presetColumnOffset
            width           : buttonHeight
            height          : buttonHeight
            buttonBorderWidth   : 0
            buttonActiveColor   : colors.canvas
            buttonHoverColor    : buttonActiveColor
            buttonSelectedColor : buttonActiveColor
            hoveringEnabled : false
            anchors {
                bottom          : parent.bottom
                horizontalCenter: miniboardFrame.horizontalCenter
                topMargin       : 2
                bottomMargin    : 2
            }
        }

        YaLabel {
            id              : columnsPlus
            enabled         : ( ( presetMode == "resize" ) && (preset_columns <maxcolumns ) ) || ( ( presetMode == "offset" ) && (presetColumnOffset <columns - 1) )
            buttonText      : (presetMode == "resize" ) ? "+" : ">"
            width           : buttonHeight
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom      : presetColumnsText.bottom
                left        : presetColumnsText.right
            }
            onClicked       : { 
                if (presetMode == "resize" ) {
                    preset_columns++ ; if ( isNxt ) { columns = preset_columns ; resetBoard() }
                } else {
                    presetColumnOffset++
                }
            }
        }

    }

// *********************************************** Preset Bottom Buttons

	Rectangle {
        id                  : presetButtons
        visible             : ( screenMode == "Preset" )
        width               : baseWidth
        height              : buttonHeight
		color               : ( prevScreenMode == "" ) ? colors.canvas : dimState ? "black" : colors.canvas
        anchors {
            bottom          : parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        YaLabel {
            id              : infoScreenButton
            buttonText      : "Info"
            width           : buttonWidth
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                horizontalCenter : parent.horizontalCenter
                bottom      : parent.bottom
            }
            onClicked       : { prevScreenMode = screenMode ; screenMode = "Info" }
        }

        YaLabel {
            id              : boardScreenButton
            buttonText      : "Life"
            width           : buttonWidth
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                right       : parent.right
                bottom      : parent.bottom
            }
            // ( new example > ) new rows and columns count > new cellSize > recalculate Theme border sizes
            onClicked       : { selectTheme(activeTheme); prevScreenMode = screenMode ;  screenMode = "Life" }
        }

    }

}
