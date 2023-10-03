import QtQuick 2.1
import BasicUIControls 1.0

/*

  Filename : ScrollMenu.qml
  Author : JackV2020 (github) JackV (Toon)
  Purpose : Provide an easy way to implement a drop down selection menu on Toon
  Date : august 2023

  Most important properties :

	scrollmenuArray : input array with all items the same type
	selectedItemIndex : index of selected item in scrollMenu 0 .. scrollMenu.length - 1
	selectedItem : value of the selected item

  Basic feedback action
	When you want to start an action immediately after selecting an item :
	start action like : onItemSelected : { aFunctionInYourApp(selectedItemIndex) }
					or : onItemSelected : { aFunctionInYourApp(selectedItem) }

  Controlled feedback action
	When you do not want an immediate action after selecting an item you have 2 options :
	- do not use onItemSelected like above but create your own button OR.......
	- use an optional Go button which can be shown on top of the main button :
	use : goButton : true
	start action like : onGoButtonClicked : { aFunctionInYourApp(selectedItemIndex) }
					or : onGoButtonClicked : { aFunctionInYourApp(selectedItem) }

 Check the code below for more properties you can use.

 Example implementations are in 'LifeScreen.qml' of the app named 'life'

*/

Item {
	id: scrollmenu

// ********************************************************** Properties

// Data Interface properties

	property variant scrollmenuArray	// Input array with all items the same type
	property int	 selectedItemIndex	// Output
	property string  selectedItem : ""	// Output

	property string scrollMenuTitle : ""	// If empty you see the next on top of the list : Select 1 of 'scrollmenuArray.length'

	property bool cellNumberPrefix : false  // optional prefix items with 1), 2), 3) etc

	width : buttonWidth
	height : buttonHeight

	property variant prevScrollmenuArray : []	// We remember the previous menu so we can see if need to rebuild it

// the next forces the scroll menu to be shown on top of all siblings
	z : showScrollMenu ? 1 : 0

// Configuration properties

	// Default is to hide the Go button
	property bool goButton : false

	// Auto hide the scroll menu when not scrolling for some seconds
	property bool autoHideScrollMenu : true
	property int autoHideScrollMenuSeconds : 10

	property int buttonWidth : isNxt ? 200 : 160	// Total width, including optional Go button
	property int buttonHeight : isNxt ?  50 : 40	// Total height, including optional Go button

	property int buttonRadius : 5					// Radius of the button(s)
	property int buttonBorderWidth : 2				// Border width of the button(s)

	property int showItems : isNxt ? 5 : 4			// Number of items to show
	property bool showScrollMenu : false			// Initially the menu is hidden

	property int itemWidth : isNxt ? 300 : 240
	property int itemHeight : isNxt ?  60 : 48

	property int itemRadius : itemHeight / 2
	property int itemBorderWidth : 1

	property string fontFamily : qfont.regular.name
	property string buttonText : "buttonText"
	property string buttonColor : "grey"
	property string buttonBorderColor : "black"
	property string buttonTextColor : "black"
	property bool buttonTextBold : false

	property string itemTextColor : "black"
	property bool itemTextBold : false

	// gradientColor1 is highlighting the selected cell
	// gradientColor2 is for making other cells darker
													// another nice combination :
	property string gradientColor1 : colors.canvas  // "lightsteelblue"
	property string gradientColor2 : "dimgrey"		// "blue"

	property int buttonPixelSize : isNxt ? 30 : 24
	property int itemPixelSize : isNxt ? 50 : 40

	property bool alreadySelectedOnce
	
// *********************************************************** Functions

// ***** Main Button

	function mainButtonClicked(){
	
		alreadySelectedOnce = false

// Setup / update scrollmenuModel with current contents of scrollmenuArray

// After you made a selection the buttonText is updated to the item you selected
//  so the next time you press the button we want to highlight your last selection
//  using the index of the buttonText

		var differenceFound = (prevScrollmenuArray.length != scrollmenuArray.length)
		var i = 0
		while ( ( ! differenceFound ) && (i < scrollmenuArray.length )){ differenceFound = (prevScrollmenuArray[i] != scrollmenuArray[i] ) ; i++ }

		try { selectedItemIndex=Math.max(0,scrollmenuArray.indexOf(buttonText)) }
		catch(err) { selectedItemIndex=0 }

		if (differenceFound) {
			if (scrollmenuModel.count == 0) {					// first time button is pressed
				scrollmenuModel.append({id: 0 , text : ""})		// this is filled with the right value at the end of this function
				var count = 0									// count all items
				var itemText = ""
				for (var i = 0 ; i < scrollmenuArray.length ; i++ ){
					itemText = scrollmenuArray[i]
					if (itemText.charAt(0) != " " ) { count++ } // Entries starting with a  " " are used as seperators
					if (cellNumberPrefix && ( itemText.charAt(0) != " " )) {
						scrollmenuModel.append({id: (i+1) , text : (count) + ") "+ itemText})
					} else {
						scrollmenuModel.append({id: (i+1) , text : itemText})
					}
				}
			} else { // not first time so we need to update because array may have changed
				var i = 0
				var count = 0									// count all items
				var itemText = ""
				while ( ( i < scrollmenuArray.length ) && (i+1 < scrollmenuModel.count) ) {
					itemText = scrollmenuArray[i]
					if (itemText.charAt(0) != " " ) { count++ } // Entries starting with a  " " are used as seperators
					if (cellNumberPrefix && ( itemText.charAt(0) != " " )) {
						scrollmenuModel.setProperty(i+1, "text", (count) + ") "+ itemText )
					} else {
						scrollmenuModel.setProperty(i+1, "text", itemText )
					}
					i=i+1
				}
				while ( i < scrollmenuArray.length ) {			// the array may have more items than before
					itemText = scrollmenuArray[i]
					if (itemText.charAt(0) != " " ) { count++ } // Entries starting with a  " " are used as seperators
					if (cellNumberPrefix && ( itemText.charAt(0) != " " )) {
						scrollmenuModel.append({id: (i+1) , text : (count) + ") "+ itemText})
					} else {
						scrollmenuModel.append({id: (i+1) , text : itemText})
					}
					i=i+1
				}

				// the array may have less items than before so we may need to remove delegates
				var end = scrollmenuModel.count - 1
				while (end > scrollmenuArray.length ) {
					scrollmenuModel.remove(end)
					end = end - 1
				}

			}
			if (scrollMenuTitle == "") { scrollmenuModel.setProperty(0, "text", "Select 1 of " + count ) }
			else						{ scrollmenuModel.setProperty(0, "text", scrollMenuTitle) }
		}
		showScrollMenu = true
	}

	Timer {
		id: hideScrollMenuTimer
		interval: autoHideScrollMenuSeconds * 1000
		running: showScrollMenu && autoHideScrollMenu
		repeat: true
		onTriggered: { showScrollMenu = false }
	}

// ***** Optional Go Button

	signal goButtonClicked()

	function goButtonClickedFN(index){
		goButtonClicked()
	}

// ***** Item Select Button

// This one has a timer to make sure that the scroll menu is gone before the signal is given

	signal itemSelected()
	property bool itemSelectReady : false

	function selectionClicked(index){
	
		if ((index == 0) || ( scrollmenuArray[index - 1].charAt(0)== " ") ){	// skip for the scrollMenuTitle and categories
			showScrollMenu = false
			prevScrollmenuArray = scrollmenuArray.slice()						// remember last input
		} else {
			if ( ( (alreadySelectedOnce) && ( selectedItemIndex == Math.max(0,index - 1) ) )  || ( selectedItemIndex == Math.max(0,index - 1) ) ) {
// clicked same item 2x OR clicked same item as previous time a selection was made
// Update output variables and text on button
				selectedItemIndex = Math.max(0,index - 1)
				selectedItem = scrollmenuArray[selectedItemIndex]
				buttonText = selectedItem
				itemSelectReady = true  // start the timer below
				showScrollMenu = false
				prevScrollmenuArray = scrollmenuArray.slice()	// remember last input
			} else {
				selectedItemIndex = Math.max(0,index - 1)
				alreadySelectedOnce = true
			}
		}
	}

	Timer {
		id: itemSelectedTimer
		interval: 50
		running: itemSelectReady
		repeat: true
// signal to object that item is selected
		onTriggered: { itemSelected(); itemSelectReady = false }
	}

// *********************************************** Object implementation

// ***** Main Button

	Rectangle {
		id : mainButton
		visible : ! showScrollMenu
		width : goButton ? ( parent.width - buttonHeight ) : parent.width
		height : parent.height
		color : buttonColor
		radius : buttonRadius
		anchors {
			top : parent.top
			horizontalCenter : parent.horizontalCenter
		}
		border  {
			width : buttonBorderWidth
			color : buttonBorderColor
		}
		Text {
			text : buttonText
			width : parent.width
			anchors {
				verticalCenter : parent.verticalCenter
				horizontalCenter: parent.horizontalCenter
			}
			wrapMode : Text.WordWrap
			horizontalAlignment : Text.AlignHCenter
			color : buttonTextColor
			font	{
				pixelSize : buttonPixelSize
				family : fontFamily
				bold : buttonTextBold
			}
		}
		MouseArea {
			anchors.fill : parent
			onClicked : { mainButtonClicked() }
		}
	}

// ***** Optional Go Button

	Rectangle {
		id : appgoButton
		visible : goButton && ( ! showScrollMenu )
		width : buttonHeight
		height : buttonHeight
		color : buttonColor
		radius : buttonRadius
		anchors {
			top : mainButton.top
			left : mainButton.right
		}
		border  {
			width : buttonBorderWidth
			color : buttonBorderColor
		}
		Text {
			text : "Go"
			width : parent.width
			anchors {
				verticalCenter : parent.verticalCenter
				horizontalCenter: parent.horizontalCenter
			}
			wrapMode : Text.WordWrap
			horizontalAlignment : Text.AlignHCenter
			color : buttonTextColor
			font	{
				pixelSize : buttonPixelSize
				family : fontFamily
				bold : buttonTextBold
			}
		}
		MouseArea {
			anchors.fill : parent
			onClicked : { goButtonClickedFN() }
		}
	}

// ***** Item Select Button

	Rectangle {
		id : selection
		visible : showScrollMenu
		width : parent.width
		height : itemHeight * ( showItems - 1)
		color : "transparent" // see what's underneath when you pull the menu to far up or down :-)
		anchors {
			top : parent.top
			horizontalCenter : parent.horizontalCenter
		}

		ListModel { id : scrollmenuModel }

		GridView {
			id : scrollmenuGrid
			anchors.fill : parent
			cellWidth : Math.max( itemWidth , buttonWidth / 2 + 2 ) // force 1 column of cells
			cellHeight : itemHeight
			model : scrollmenuModel
			anchors {
				horizontalCenter: parent.horizontalCenter
			}

			delegate:
			Rectangle {
				width : Math.max( itemWidth - buttonBorderWidth , buttonWidth / 2 + 2 )  // force 1 column of cells
				height : itemHeight
				radius : itemRadius
				border  {
					width : itemBorderWidth
					color : buttonBorderColor
				}
				anchors {
					horizontalCenter : parent.horizontalCenter
				}
				gradient: Gradient  {
						GradientStop { position: 0.0; color: gradientColor1 }
						GradientStop { position: ( (index == selectedItemIndex + 1 ) ) ? 0.0 : 1.0; color: gradientColor2 }
				}
				Text {
					text : model.text
					width : parent.width - 2
					anchors {
						verticalCenter : parent.verticalCenter
						horizontalCenter: parent.horizontalCenter
					}
					font	{
						pixelSize : itemPixelSize
						family : fontFamily
						bold : itemTextBold
					}
					wrapMode : Text.WordWrap
					horizontalAlignment : Text.AlignHCenter
					color : itemTextColor
				}

				MouseArea {
					anchors.fill : parent
					onClicked : { hideScrollMenuTimer.stop() ; hideScrollMenuTimer.start() ; selectionClicked(index)  }
					onPositionChanged : { hideScrollMenuTimer.stop() ; hideScrollMenuTimer.start() }
				}
			}
		}
	}
}
