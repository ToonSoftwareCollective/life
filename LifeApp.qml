import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0;
import FileIO 1.0

App {

    property url          tileUrl       : "LifeTile.qml"
    property LifeTile     lifeTile

    property url          lifeScreenUrl : "LifeScreen.qml"
    property LifeScreen   lifeScreen

    property bool keepLifeOnScreen      : false
    
    // The next 6 are for some book keeping to put messages on the tile when there is something new
    // Calculation is done in LifeScreen.qml where everything happens anyway
    
    property real examplesCount          : 0
    property real examplesCountPrevious  : 0
    property real examplesCountNew       : examplesCount - examplesCountPrevious

    property real themesCount            : 0
    property real themesCountPrevious    : 0
    property real themesCountNew         : themesCount - themesCountPrevious
        
// ---------------------------------------- Register the App in the GUI
    
    function init() {

        const args = {
            thumbCategory       : "general",
            thumbLabel          : "Life",
            thumbIcon           : "qrc:/tsc/pushon.png",
            thumbIconVAlignment : "center",
            thumbWeight         : 30
        }
// I would like :
//            thumbIcon           : "qrc:/tsc/life.png",

        registry.registerWidget("tile", tileUrl, this, "lifeTile", args);

        registry.registerWidget("screen", lifeScreenUrl, this, "lifeScreen");

    }

// ------------------------------------- Actions right after APP startup

    Component.onCompleted: {

        log("App onCompleted Started")

        log("App onCompleted Completed")
    }
    
// -------------------- A function to log to the console with timestamps

    function log(tolog) {

        var now      = new Date();
        var dateTime = now.getFullYear() + '-' +
                ('00'+(now.getMonth() + 1)   ).slice(-2) + '-' +
                ('00'+ now.getDate()         ).slice(-2) + ' ' +
                ('00'+ now.getHours()        ).slice(-2) + ":" +
                ('00'+ now.getMinutes()      ).slice(-2) + ":" +
                ('00'+ now.getSeconds()      ).slice(-2) + "." +
                ('000'+now.getMilliseconds() ).slice(-3);
// This is a line with the name of the app in it so I can filter the log
        console.log(dateTime+' Life : ' + tolog.toString())
        
    }
        
// ---------------------------------------------------------------------

}
