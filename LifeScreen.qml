import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0

Screen {
    id                              : lifeScreen

    // A developer may want to see some logging
    property bool debug             : false

/*

 HOWTO add a composition
 
 When you just want to add compositions read this short howto
 When you want to know how the algorithm works read the next section

 To add a composition to this app :

 1) Search for toon in this code and you will find where to do it.
        Note the line which starts with : // A blinker on Toon
 2) Give it a name in the array where you found "Toon", "Blinker" ....
 3) Draw your new Toon composition on paper/have it on screen
        and rectangle around it and choose the left upper cell as 0,0
 4) Fill a variant with a name ending at Data like toonData
      for the grid, row by row and column by column.
 5) Add a case in the function addExample(selectedItem) like for "Toon"


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

    property int selectedTheme              : 0

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

// ******************************************************** Compositions


// More complex thing should only be made available on Toon 2

    property variant selectExamples : 
    isNxt ?
       [ "Toon", "Blinker", "To 4 Blinkers", "Random", "Glider"
      , "4 Gliders", "Small Spaceships", "Big Spaceship", "Upwards Spaceship"
      , "Pi", "Pulsar", "5 Pulsars", "Gosper Gun 1", "Other Gun"
        ]
    :
       [ "Toon", "Blinker", "To 4 Blinkers", "Random", "Glider" ]
    
// A blinker on Toon looks like : ( the simplest example to create a variant)
//      #
//      #
//      #
// And is defined as :

    property variant blinkerData : [
        [ 0, 0]
      , [ 1, 0]
      , [ 2, 0]
    ]

//  And this just does has to be there ;-)

// To get the idea of how to create a composition check the example above

    property variant toonData :[
        [ 0, 0] , [ 0, 1] , [ 0, 2] , [ 0, 3] , [ 0, 4] , [ 0,10] , [ 0,11] , [ 0,19] , [ 0,20] , [ 0,26] , [ 0, 31]
      , [ 1, 2] , [ 1, 9] , [ 1,12] , [ 1,18] , [ 1,21] , [ 1,26] , [ 1,27] , [ 1,31]
      , [ 2, 2] , [ 2, 8] , [ 2,13] , [ 2,17] , [ 2,22] , [ 2,26] , [ 2,28] , [ 2,31]
      , [ 3, 2] , [ 3, 8] , [ 3,10] , [ 3,11] , [ 3,13] , [ 3,17] , [ 3,19] , [ 3,20] , [ 3,22] , [ 3,26] , [ 3,28] , [ 3,31]
      , [ 4, 2] , [ 4, 8] , [ 4,13] , [ 4,17] , [ 4,22] , [ 4,26] , [ 4,29] , [ 4,31]
      , [ 5, 2] , [ 5, 8] , [ 5,13] , [ 5,17] , [ 5,22] , [ 5,26] , [ 5,29] , [ 5,31]
      , [ 6, 2] , [ 6, 9] , [ 6,12] , [ 6,18] , [ 6,21] , [ 6,26] , [ 6,30] , [ 6,31]
      , [ 7, 2] , [ 7,10] , [ 7,11] , [ 7,19] , [ 7,20] , [ 7,26] , [ 7,31]
    ]

// A glider looks like :
//      .#.
//      ..#
//      ###
// And is defined as :

    property variant gliderData : [
        [ 0, 1]
      , [ 1, 2]
      , [ 2, 0] , [ 2, 1] , [ 2, 2]
    ]

    property variant to4BlinkersData :[
        [ 0, 1]
      , [ 1, 0] , [ 1, 1] , [ 1, 2]
      , [ 2, 0] , [ 2, 1] , [ 2, 2]
    ]

// a smallShip expands 1 row up
// so do not create one at row = 0 and col = 0 but at least row = 1 and col = 0
    property variant smallShipData :[
        [ 0, 0] , [ 0, 3]
      , [ 1, 4]
      , [ 2, 0] , [ 2, 4]
      , [ 3, 1] , [ 3, 2] , [ 3, 3] , [ 3, 4]
    ]

// and some more serious things below

    property variant gosperGliderGunData : [
        [ 0,23] , [ 0,25]
      , [ 1,21] , [ 1,25]
      , [ 2,13] , [ 2,21] , [ 2,34] , [ 2,35]
      , [ 3,12] , [ 3,13] , [ 3,14] , [ 3,15] , [ 3,20] , [ 3,25] , [ 3,34] , [ 3,35]
      , [ 4, 0] , [ 4, 1] , [ 4,11] , [ 4,12] , [ 4,14] , [ 4,16] , [ 4,21]
      , [ 5, 0] , [ 5, 1] , [ 5,10] , [ 5,11] , [ 5,12] , [ 5,14] , [ 5,17] , [ 5,21] , [ 5,25]
      , [ 6,11] , [ 6,12] , [ 6,14] , [ 6,16] , [ 6,23] , [ 6,25]
      , [ 7,12] , [ 7,13] , [ 7,14] , [ 7,15]
      , [ 8,13]
    ]

    property variant otherGliderGunData : [
        [ 0,25] , [ 0,26] , [ 0,32] , [ 0,33]
      , [ 1,25] , [ 1,26] , [ 1,32] , [ 1,33]
      , [ 2,25] , [ 2,26] , [ 2,32] , [ 2,33]
      , [ 3,25] , [ 3,26] , [ 3,27] , [ 3,31] , [ 3,32] , [ 3,33]
      , [ 4,25] , [ 4,27] , [ 4,31] , [ 4,33]
      , [ 5,25] , [ 5,28] , [ 5,30] , [ 5,33]
      , [ 6,27] , [ 6,28] , [ 6,30] , [ 6,31]

      , [11,25] , [11,26] , [11,32] , [11,33]
      , [12,25] , [12,26] , [12,28] , [12,30] , [12,32] , [12,33]
      , [13,25] , [13,28] , [13,30] , [13,33]
      , [14,25] , [14,26] , [14,27] , [14,31] , [14,32] , [14,33]

      , [23, 1] , [23, 2] , [23, 3] , [23, 4] , [23,12] , [23,13]
      , [24, 0] , [24, 4] , [24,11] , [24,14]
      , [25, 0] , [25,11] , [25,14] , [25,15]
      , [26, 1] , [26, 3] , [26, 4] , [26, 6] , [26,11] , [26,14]
      , [27, 4] , [27, 5] , [27, 6] , [27,13]

      , [29, 4] , [29, 5] , [29, 6] , [29,13]
      , [30, 1] , [30, 3] , [30, 4] , [30, 6] , [30,11] , [30,14]
      , [31, 0] , [31,11] , [31,14] , [31,15] , [31,27] , [31,28]
      , [32, 0] , [32, 4] , [32,11] , [32,14] , [32,27] , [32,28]
      , [33, 1] , [33, 2] , [33, 3] , [33, 4] , [33,12] , [33,13]

    ]

    property variant piData : [
        [ 0,11] , [ 0,12]
      , [ 1,6 ] , [ 1,7 ] , [ 1,9 ] , [ 1,14] , [ 1,16] , [ 1,17]
      , [ 2,6 ] , [ 2,17]
      , [ 3,7 ] , [ 3,8 ] , [ 3,15] , [ 3,16]
      , [ 4,4 ] , [ 4,5 ] , [ 4,6 ] , [ 4,9 ] , [ 4,10] , [ 4,11] , [ 4,12] , [ 4,13] , [ 4,14] , [ 4,17] , [ 4,18] , [ 4,19]
      , [ 5,4 ] , [ 5,7 ] , [ 5,16] , [ 5,19]
      , [ 6,1 ] , [ 6,2 ] , [ 6,4 ] , [ 6,6 ] , [ 6,17] , [ 6,19] , [ 6,21] , [ 6,22]
      , [ 7,1 ] , [ 7,3 ] , [ 7,5 ] , [ 7,18] , [ 7,20] , [ 7,22]
      , [ 8,3 ] , [ 8,20]
      , [ 9,1 ] , [ 9,4 ] , [ 9,19] , [ 9,22]
      , [10,4 ] , [10,12] , [10,13] , [10,14] , [10,19]
      , [11,0 ] , [11,4 ] , [11,12] , [11,14] , [11,19] , [11,23]
      , [12,0 ] , [12,4 ] , [12,12] , [12,14] , [12,19] , [12,23]
      , [13,4 ] , [13,19]
      , [14,1 ] , [14,4 ] , [14,19] , [14,22]
      , [15,3 ] , [15,20]
      , [16,1 ] , [16,3 ] , [16,5 ] , [16,18] , [16,20] , [16,22]
      , [17,1 ] , [17,2 ] , [17,4 ] , [17,6 ] , [17,17] , [17,19] , [17,21] , [17,22]
      , [18,4 ] , [18,7 ] , [18,16] , [18,19]
      , [19,4 ] , [19,5 ] , [19,6 ] , [19,9 ] , [19,10] , [19,11] , [19,12] , [19,13] , [19,14] , [19,17] , [19,18] , [19,19]
      , [20,7 ] , [20,8 ] , [20,15] , [20,16]
      , [21,6 ] , [21,17]
      , [22,6 ] , [22,7 ] , [22,9 ] , [22,14] , [22,16] , [22,17]
      , [23,11] , [23,12]
    ]

// a pulsar expands 1 column to the left and 1 to the right and 1 row up and 1 down
// so do not create one at row = 0 and col = 0 but at least row = 1 and col = 1
    property variant pulsarData : [
        [ 0, 2] , [ 0, 3] , [ 0, 4] , [ 0, 8] , [ 0, 9] , [ 0,10]

      , [ 2, 0] , [ 2, 5] , [ 2, 7] , [ 2,12]
      , [ 3, 0] , [ 3, 5] , [ 3, 7] , [ 3,12]
      , [ 4, 0] , [ 4, 5] , [ 4, 7] , [ 4,12]
      , [ 5, 2] , [ 5, 3] , [ 5, 4] , [ 5, 8] , [ 5, 9] , [ 5,10]

      , [ 7, 2] , [ 7, 3] , [ 7, 4] , [ 7, 8] , [ 7, 9] , [ 7,10]
      , [ 8, 0] , [ 8, 5] , [ 8, 7] , [ 8,12]
      , [ 9, 0] , [ 9, 5] , [ 9, 7] , [ 9,12]
      , [10, 0] , [10, 5] , [10, 7] , [10,12]

      , [12, 2] , [12, 3] , [12, 4] , [12, 8] , [12, 9] , [12,10]

    ]

    property variant bigShipData : [
        [ 0,33]
      , [ 1,16] , [ 1,32] , [ 1,34]
      , [ 2, 6] , [ 2, 8] , [ 2,15] , [ 2,21] , [ 2,22] , [ 2,31]
      , [ 3, 6] , [ 3,11] , [ 3,16] , [ 3,18] , [ 3,19] , [ 3,20] , [ 3,21] , [ 3,22] , [ 3,23] , [ 3,28] , [ 3,29]
      , [ 4, 6] , [ 4, 8] , [ 4, 9] , [ 4,10] , [ 4,11] , [ 4,12] , [ 4,13] , [ 4,14] , [ 4,15] , [ 4,26] , [ 4,29] , [ 4,31] , [ 4,32] , [ 4,33]
      , [ 5, 9] , [ 5,15] , [ 5,23] , [ 5,24] , [ 5,25] , [ 5,26] , [ 5,31] , [ 5,32] , [ 5,33]
      , [ 6, 4] , [ 6, 5] , [ 6,23] , [ 6,24] , [ 6,25] , [ 6,27]
      , [ 7, 1] , [ 7, 4] , [ 7, 5] , [ 7,13] , [ 7,14] , [ 7,23] , [ 7,24]
      , [ 8, 1] , [ 8, 4]
      , [ 9, 0]
      , [10, 1] , [10, 4]
      , [11, 1] , [11, 4] , [11, 5] , [11,13] , [11,14] , [11,23] , [11,24]
      , [12, 4] , [12, 5] , [12,23] , [12,24] , [12,25] , [12,27]
      , [13, 9] , [13,15] , [13,23] , [13,24] , [13,25] , [13,26] , [13,31] , [13,32] , [13,33]
      , [14, 6] , [14, 8] , [14, 9] , [14,10] , [14,11] , [14,12] , [14,13] , [14,14] , [14,15] , [14,26] , [14,29] , [14,31] , [14,32] , [14,33]
      , [15, 6] , [15,11] , [15,16] , [15,18] , [15,19] , [15,20] , [15,21] , [15,22] , [15,23] , [15,28] , [15,29]
      , [16, 6] , [16, 8] , [16,15] , [16,21] , [16,22] , [16,31]
      , [17,16] , [17,32] , [17,34]
      , [18,33]
    ]

    property variant upShipData : [
        [ 0, 1] , [ 0, 2] , [ 0, 5] , [ 0, 6]
      , [ 1, 3] , [ 1, 4]
      , [ 2, 3] , [ 2, 4]
      , [ 3, 0] , [ 3, 2] , [ 3, 5] , [ 3, 7]
      , [ 4, 0] , [ 4, 7]

      , [ 6, 0] , [ 6, 7]
      , [ 7, 1] , [ 7, 2] , [ 7, 5] , [ 7, 6]
      , [ 8, 2] , [ 8, 3] , [ 8, 4] , [ 8, 5]

      , [10, 3] , [10, 4]
      , [11, 3] , [11, 4]
    ]

// **************************************************************** Code

    Component.onCompleted: {
        app.log("LifeScreen onCompleted Started")
        lifeSetup()
        selectTheme( selectedTheme )   // color and shape settings
        if (isNxt) { addExample("Gosper Gun 1") }
        else       { addExample("Glider") }
        app.log("LifeScreen onCompleted Completed")
    }

// ---------------------------------------------------------------------

    onVisibleChanged: {
        if ( visible ) {
            debug && app.log("You can see me !   8-)")
// we need to know if we are in dimState (hide things, change colors...)
            dimState = app.lifeTile.dimState
        } else { // the screen is hiding and we want it to com back when the app is still running
            debug && app.log("You can't see me ! |-)")
// Trick to keep stay on screen during dimState
// The tile uses app.keepLifeOnScreen to check if it needs to call this screen in dimState
            app.keepLifeOnScreen = alive
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

    function resetBoard() {
        for( var i = 0 ; i < (maxcolumns*maxrows) ; i++ ) {
            lifeModel.setProperty(i , "lifeState", false)
            arrayHiddenGrid[i]=0
        }
        for (var i = 0 ; i < (maxcolumns*2) + (maxrows*2) + 4 ; i++ ){
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

// Theme 1 has a heartbeat like thing in it ;-)

    Timer {
        id: theme1HeartBeatTimer
        interval: dimState ? 10000 : 1000
        running: alive && (selectedTheme == 1)
        repeat: true
        onTriggered: {
            if (borderWidthLife == cellSize)
                  { borderWidthLife = cellSize / 3 ; borderWidthDimLife = cellSize / 3  }
             else { borderWidthLife = cellSize     ; borderWidthDimLife = cellSize }
        }
    }

// ---------------------------------------------------------------------

    function selectTheme(theme) {

        selectedTheme = theme

        switch (theme) {
        case 0:                               // theme 1 : Black / White
            // Life screen setings
                 radiusLife              = 0
            // Live cell
                 colorLife               = "black"
                 borderColorLife         = "black"
                 borderWidthLife         = 0
            // Dead not clickable
                 colorDeadNoClick        = "lightgrey"
                 borderColorDeadNoClick  = "lightgrey"
                 borderWidthDeadNoClick  = 0
            // Dead clickable
                 colorDeadClick          = "grey"
                 borderColorDeadClick    = "black"
                 borderWidthDeadClick    = 1

            // dimState settings
                 radiusDim              = 0
            // Live cell
                 colorDimLife           = "lightgrey"
                 borderColorDimLife     = "lightgrey"
                 borderWidthDimLife     = 0
            // Dead cell
                 colorDimDead           = "black"
                 borderColorDimDead     = "black"
                 borderWidthDimDead     = 0
            break
        case 1:                    // theme 2 : Red Rings with heartbeat
            // Life screen setings
                 radiusLife              = cellSize / 2
            // Live cell
                 colorLife               = "white"
                 borderColorLife         = "red"
                 borderWidthLife         = cellSize / 3
            // Dead not clickable
                 colorDeadNoClick        = "lightyellow"
                 borderColorDeadNoClick  = "white"
                 borderWidthDeadNoClick  = 1
            // Dead clickable
                 colorDeadClick          = "white"
                 borderColorDeadClick    = "pink"
                 borderWidthDeadClick    = 1

            // dimState settings
                 radiusDim              = cellSize / 2
            // Live cell
                 colorDimLife           = "white"
                 borderColorDimLife     = "red"
                 borderWidthDimLife     = cellSize / 3
            // Dead cell
                 colorDimDead           = "black"
                 borderColorDimDead     = "black"
                 borderWidthDimDead     = 0
            break
        case 2:                                       // theme 3 : Brown
            // Life screen setings
                 radiusLife              = cellSize / 4
            // Live cell
                 colorLife               = "brown"
                 borderColorLife         = "brown"
                 borderWidthLife         = 0
            // Dead not clickable
                 colorDeadNoClick        = "lightyellow"
                 borderColorDeadNoClick  = "white"
                 borderWidthDeadNoClick  = 1
            // Dead clickable
                 colorDeadClick          = "white"
                 borderColorDeadClick    = "pink"
                 borderWidthDeadClick    = 1

            // dimState settings
                 radiusDim              = cellSize / 4
            // Live cell
                 colorDimLife           = "brown"
                 borderColorDimLife     = "broen"
                 borderWidthDimLife     = 0
            // Dead cell
                 colorDimDead           = "black"
                 borderColorDimDead     = "black"
                 borderWidthDimDead     = 0
            break
        case 3:                                        // theme 4 : Lime
            // Life screen setings
                 radiusLife              = 0
            // Live cell
                 colorLife               = "lime"
                 borderColorLife         = "lime"
                 borderWidthLife         = 0
            // Dead not clickable
                 colorDeadNoClick        = "lightyellow"
                 borderColorDeadNoClick  = "white"
                 borderWidthDeadNoClick  = 1
            // Dead clickable
                 colorDeadClick          = "white"
                 borderColorDeadClick    = "yellow"
                 borderWidthDeadClick    = 1

            // dimState settings
                 radiusDim              = 0
            // Live cell
                 colorDimLife           = "lime"
                 borderColorDimLife     = "lime"
                 borderWidthDimLife     = 0
            // Dead cell
                 colorDimDead           = "black"
                 borderColorDimDead     = "black"
                 borderWidthDimDead     = 0
            break
        }

    }


// **************************************************** Preset functions

    function togglePreset(row,col,rowOrientation,colOrientation,dots) {

// This function is used to add/remove a complete composition on the screen.
//
//  rows are numbered from top to bottom, columns from left to right
//
// columns 0 1 2 3 ..
//  rows 0
//       1
//       2
//       3
//       :
//
//  row, col  : position for the origin row and column of the preset
//              2,4 means 3rd row, 5th column because count starts at 0
//
//  dots      : array of points of Preset like :
//             [ [0,1] , [1,2] , [2,0] , [2,1] , [2,2] ]
//
//          the . in the text below point at the origin
//                  .1                     .#
//        order >     2     result >         #
//                  345                    ###
//
//  The next 2 allow the composition to be be rotated on the screen :
//
//  rowOrientation    : 1 build down  ; -1 build up
//  colOrientation    : 1 build right ; -1 build left
//
        for (var i = 0 ; i < dots.length ; i ++) {
            toggleCell((row+rowOrientation*dots[i][0]),
                       (col+colOrientation*dots[i][1]))
        }
    }

// ---------------------------------------------------------------------

    function minRowsCols(minrows,mincols) {
// can be used to force screen size
            if ((rows < minrows) || (columns<mincols) ) {
                rows=minrows
                columns=mincols
                preset_rows=minrows
                preset_columns=mincols
                resetBoard()
            }
    }

// ---------------------------------------------------------------------

    function addExample(selectedItem) {
        switch (selectedItem) {
        case "Toon"             : wrapMode = false; minRowsCols(12,36); togglePreset(2,2,1,1,toonData); break
        case "Blinker"          : wrapMode = false; minRowsCols(5,5); togglePreset(1,2,1,1,blinkerData); break
        case "To 4 Blinkers"    : wrapMode = false; minRowsCols(11,11); togglePreset(4,4,1,1,to4BlinkersData); break
        case "Random"           : randomLife(); break
        case "Gosper Gun 1"     : wrapMode = false; minRowsCols(22,36); speed = 6 ; togglePreset(0, 0,1,1,gosperGliderGunData); break
        case "Other Gun"        : wrapMode = false; minRowsCols(37,48); speed = 6 ; togglePreset(0, 0,1,1,otherGliderGunData); break
        case "Pi"               : minRowsCols(24,24); togglePreset(0, 0,1,1,piData); break
        case "Glider"           : wrapMode = true; minRowsCols(7,15); speed = 4 ; togglePreset(1,1,1,1,gliderData); break
        case "4 Gliders"        : wrapMode = true; minRowsCols(10,20); speed = 9
                                togglePreset(1,1,1,1,gliderData); togglePreset(1,6,1,1,gliderData); togglePreset(1,11,1,1,gliderData); togglePreset(6,14,1,1,gliderData); break
        case "Small Spaceships" : wrapMode = true; minRowsCols(8,40); speed = 6
                                togglePreset(1,0,1,1,smallShipData ); togglePreset(7,8,-1,1,smallShipData ); togglePreset(2,25,1,1,smallShipData ); break
        case "Pulsar"         : wrapMode = false; minRowsCols(15,15); speed = 6
                                togglePreset( 1,1,1,1,pulsarData ); break
        case "5 Pulsars"        : wrapMode = false; minRowsCols(39,39); speed = 6
                                togglePreset( 1,1,1,1,pulsarData ); togglePreset( 1,25,1,1,pulsarData ); togglePreset(13,13,1,1,pulsarData );
                                togglePreset(25,1,1,1,pulsarData ); togglePreset(25,25,1,1,pulsarData ); break
        case "Big Spaceship"   : wrapMode = true; minRowsCols(21,50); speed = 6; togglePreset(1,34,1,-1,bigShipData); break
        case "Upwards Spaceship": wrapMode = true; minRowsCols(30,12); speed = 9 ; togglePreset(18,2,1,1,upShipData); break

        default             : app.log("Error : >"+selectedItem+"< Not implemented ")
        }
    }

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

// This is the screen which is shown as first after a GUI restart / reboot
// It is also available as a button on the Preset screen

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

            + "\n\nOn the Presets page are some examples which can be found on many places on the Internet."
            +   "\nWhen you have issues, remarks or suggestions for additional examples you can find me on github as JackV2020."

            + "\n\nThe inital setup of the app is an example of the presets."
            +   "\nAll you need to do is click \"Start Life\" and increase the Speed. "
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

    ScrollMenu {
        id                  : selectThemeMenu
        visible             : ( screenMode == "Life" ) && (! dimState) // hide buttons in dimstate
        buttonText          : "Select Theme"
        scrollmenuArray     : selectThemesData
        scrollMenuTitle     : "Select Theme"
        autoHideScrollMenuSeconds : 3
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
            buttonText      : modeClickable ? "Click cells" : "No clicks"
            width           : buttonWidth
            height          : parent.height
            hoveringEnabled : isNxt
            anchors {
                left        : lifeSpeedplus.right
            }
            onClicked       : { modeClickable = ! modeClickable }
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
            bottom          : board.top
            bottomMargin    : 2
            horizontalCenter: parent.horizontalCenter
        }
    }

// the board which we see on the screen

	Rectangle {
        id                  : board
        visible             : ( screenMode == "Life" )
        width               : boardWidth
        height              : boardHeight
		color               : dimState ? "black" : colors.canvas
        anchors {
            top             : parent.top
            horizontalCenter: parent.horizontalCenter
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

// Activate one of the delegates below depending on the looks you want
// just copy and paste over the current one

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

                delegate:
                Rectangle {
                    width       : isNxt ? 6 : 5
                    height      : isNxt ? 6 : 5
                    color       : "green"
                    visible     : model.lifeState // && (index < columns * rows )
                }
            }
        }

        ScrollMenu {
            id                  : selectLife
            buttonText          : "Life Examples"
            scrollmenuArray     : selectExamples
            cellNumberPrefix    : true
            showItems           : 6
            anchors {
//                top             : x3x3.top
                top             : parent.top
                horizontalCenter: presetScreenText.horizontalCenter
                topMargin       : buttonHeight
            }
            fontFamily          : qfont.regular.name
            buttonPixelSize     : isNxt ? 20 : 16
            itemPixelSize       : isNxt ? 20 : 16
            onItemSelected      : { addExample(selectedItem) }
        }

        Text {
            id                  : presetScreenText
            width               : parent.width / 2
            height              : parent.height / 2
            wrapMode            : Text.WordWrap
            horizontalAlignment : Text.AlignLeft
            anchors {
                top             : selectLife.bottom
                right           : parent.right
                topMargin       : buttonHeight / 2
            }
//            lineHeight          : 0.8
            font    {
                pixelSize       : isNxt ? 20 : 16
                family          : qfont.regular.name
                bold            : false
            }
            text:
            "Above you see a scroll menu to add some examples."
        +   "\nClick and wait...., When the board is too small it is cleared and resized."
        +   "\nClick the same again to remove the selection."
        +   "\n\nOn the left you can change the size of the board."
        +   "Resizing the board takes time...."
        +   "\nAnd the bigger the board, the more the work, the slower the app....."
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
            onClicked       : { preset_columns = columns ; preset_rows = rows ; resetBoard() }
        }

        YaLabel {
            id              : rowsPlus
            enabled         : (preset_rows <maxrows)
            buttonText      : "+"
            width           : buttonHeight
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom      : presetRowText.top
                left        : presetRowText.left
            }
            onClicked       : { if (preset_rows <maxrows ) {preset_rows++ ; if ( isNxt ) { rows = preset_rows ; resetBoard() } } }
        }

        YaLabel {
            id              : presetRowText
            buttonText      : preset_rows
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
            enabled         : (preset_rows >3 )
            buttonText      : "-"
            width           : buttonHeight
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                top         : presetRowText.bottom
                left        : presetRowText.left
            }
            onClicked       : { preset_rows-- ; if ( isNxt ) { rows = preset_rows ; resetBoard() } }
        }

        YaLabel {
            id              : columnsMinus
            enabled         : (preset_columns >3 )
            buttonText      : "-"
            width           : buttonHeight
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom      : presetColumnsText.bottom
                right       : presetColumnsText.left
            }
            onClicked       : { preset_columns-- ; if ( isNxt ) { columns = preset_columns ; resetBoard() } }
        }

        YaLabel {
            id              : presetColumnsText
            buttonText      : preset_columns
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
            enabled         : (preset_columns <maxcolumns )
            buttonText      : "+"
            width           : buttonHeight
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom      : presetColumnsText.bottom
                left        : presetColumnsText.right
            }
            onClicked       : { if (preset_columns <maxcolumns ) {preset_columns++ ; if ( isNxt ) { columns = preset_columns ; resetBoard() } } }
        }

        YaLabel {
            id              : applyLayout
            visible         : ! isNxt
            enabled         : ( (preset_columns != columns ) || ( preset_rows !=rows ) )
            buttonText      : "Apply"
            width           : buttonWidth
            height          : buttonHeight
            hoveringEnabled : isNxt
            anchors {
                bottom      : columnsPlus.bottom
                left        : columnsPlus.right
                leftMargin  : buttonHeight
            }
            onClicked       : { columns = preset_columns ; rows = preset_rows ; resetBoard() }
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
            onClicked       : { prevScreenMode = screenMode ;  screenMode = "Life" }
        }

    }

}
