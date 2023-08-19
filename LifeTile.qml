import QtQuick 2.1
import qb.components 1.0

Tile {
    id                          : lifeTile

    onVisibleChanged: {
        if ( visible ) {
/*
            A trick to keep lifeScreenUrl on the screen while it is alive

            When dimState is activated while lifeScreenUrl is on the screen,
            lifeScreenUrl will run onVisibleChanged and will execute :
                app.keepLifeOnScreen = alive
            and it will be removed from the screen and the Tile will show up.

            When the tile shows up while live == true,
            app.keepLifeOnScreen == true and so we need to open the screen again.
*/
            if (app.keepLifeOnScreen) { stage.openFullscreen(app.lifeScreenUrl) } 
        }
    }

// --- Tile button


    YaLabel {
        id                      : tileButton
        buttonBorderWidth       : 0
        height                  : isNxt ? 150 : 120
        width                   : isNxt ? 150 : 120
        buttonActiveColor       : dimState ? "black" : "white"
        buttonSelectedColor     : buttonActiveColor
        buttonHoverColor        : buttonActiveColor
        hoveringEnabled         : false
        selected                : true
        enabled                 : true
        textColor               : "white"
        anchors {
            verticalCenter      : parent.verticalCenter
            horizontalCenter    : parent.horizontalCenter
        }

        onClicked               : { stage.openFullscreen(app.lifeScreenUrl) }
    }

    Image {
        id                      : lifeImage
        source                  : dimState ? "drawables/lifeDimmed.png"
                                           : "drawables/life.png"
        height                  : isNxt ? (dimState ? 50 : 100 ) 
                                        : (dimState ? 40 : 80 )
        width                   : isNxt ? (dimState ? 50 : 100 )
                                        : (dimState ? 40 : 80 )

        anchors {
            verticalCenter      : parent.verticalCenter
            horizontalCenter    : parent.horizontalCenter
        }       

    }
}
