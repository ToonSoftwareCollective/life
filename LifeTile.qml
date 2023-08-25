import QtQuick 2.1
import qb.components 1.0

Tile {
    id                              : lifeTile

    onVisibleChanged: {
        if ( visible ) {
/*
            A trick to keep lifeScreenUrl on the screen while it is alive

            When dimState is activated while lifeScreenUrl is on the screen,
            lifeScreenUrl will run onVisibleChanged and will execute :
                app.keepLifeOnScreen = alive
            and it will be removed from the screen and this Tile will show up.

            When the tile shows up while Life is still running ,
                app.keepLifeOnScreen == true 
            and we need to open the screen again while we are in dimState
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

    Text {
        id                  : examplesUpdatedMessage
        visible             : ( app.examplesCountNew != 0 )
        text                : app.examplesCount + " Examples, new : "  + app.examplesCountNew
        anchors {
            top             : tileButton.top
            horizontalCenter: tileButton.horizontalCenter
        }
        font    {
            pixelSize       : isNxt ? 20 : 16
            family          : qfont.regular.name
            bold            : true
        }
        color               : "blue"
    }

    Text {
        id                  : themesUpdatedMessage
        visible             : ( app.themesCountNew != 0 )
        text                : app.themesCount + " Themes, new : "  + app.themesCountNew
        anchors {
            bottom          : tileButton.bottom
            horizontalCenter: tileButton.horizontalCenter
        }
        font    {
            pixelSize       : isNxt ? 20 : 16
            family          : qfont.regular.name
            bold            : true
        }
        color               : "blue"
    }

}
