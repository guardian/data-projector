# Toolbar.coffee
# Tomasz (Tomek) Zemla
# tomek@datacratic.com

# Application top of the window menu toolbar.

Utility = require('./Utility.coffee')
Panel = require('./Panel.coffee')
Palette = require('./Palette.coffee')

class Toolbar extends Panel

   # E V E N T S

   @EVENT_MENU : "EVENT_MENU"
   @EVENT_INFO : "EVENT_INFO"
   @EVENT_PERSPECTIVE : "EVENT_PERSPECTIVE"
   @EVENT_ORTHOGRAPHIC : "EVENT_ORTHOGRAPHIC"
   @EVENT_DUAL : "EVENT_DUAL"
   @EVENT_RESET : "EVENT_RESET"
   @EVENT_CLEAR : "EVENT_CLEAR"
   @EVENT_BOX : "EVENT_BOX"
   @EVENT_VIEWPORT : "EVENT_VIEWPORT"
   @EVENT_SELECT : "EVENT_SELECT"
   @EVENT_VIEW_TOP : "EVENT_VIEW_TOP"
   @EVENT_VIEW_FRONT : "EVENT_VIEW_FRONT"
   @EVENT_VIEW_SIDE : "EVENT_VIEW_SIDE"
   @EVENT_SPIN_LEFT : "EVENT_SPIN_LEFT"
   @EVENT_SPIN_STOP : "EVENT_SPIN_STOP"
   @EVENT_SPIN_RIGHT : "EVENT_SPIN_RIGHT"
   @EVENT_ANIMATE : "EVENT_ANIMATE"
   @EVENT_SPIN_TOGGLE : "EVENT_SPIN_TOGGLE"
   @EVENT_SHOW_DOCUMENTS : "EVENT_SHOW_DOCUMENTS"
   @EVENT_SHOW_HELP : "EVENT_SHOW_HELP"

   # M E M B E R S
   
   dispatcher : null # map of IDs and event handlers

   # C O N S T R U C T O R

   constructor : (id) ->

      super(id)

      @createDispatcher()

      for item in @dispatcher
         $(item.id).click({ type : item.type }, @onClick)

      document.addEventListener('keydown', @onKeyDown, false)

      @initialize()


   # E V E N T   H A N D L E R S

   # Called when key pressed.
   onKeyDown : (event) =>

      # console.log event.keyCode + " : " + event.shiftKey

      modifier = Utility.NO_KEY # default

      if event.shiftKey then modifier = Utility.SHIFT_KEY

      for item in @dispatcher
         if (item.key is event.keyCode) and (item.modifier is modifier) then @notify(item.type)

   
   onClick : (event) =>
      @notify(event.data.type)

   # M E T H O D S

   # Create centralized event registration and dispatch map
   createDispatcher : =>

      # NOTE key == 0 means no shortcut assigned

      @dispatcher = [ { id : "#menuButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_MENU },
                      { id : "#infoButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_INFO },
                      { id : "#perspectiveButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_PERSPECTIVE },
                      { id : "#orthographicButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_ORTHOGRAPHIC },
                      { id : "#dualButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_DUAL },
                      { id : "#resetButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_RESET },
                      { id : "#clearButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_CLEAR },
                      { id : "#boxButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_BOX },
                      { id : "#viewportButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_VIEWPORT },
                    # { id : "#selectButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_SELECT },
                      { id : "#viewTopButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_VIEW_TOP },
                      { id : "#viewFrontButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_VIEW_FRONT },
                      { id : "#viewSideButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_VIEW_SIDE },
                      { id : "#spinLeftButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_SPIN_LEFT },
                      { id : "#spinStopButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_SPIN_STOP },
                      { id : "#spinRightButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_SPIN_RIGHT },
                    # { id : "#animateButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_ANIMATE },
                      { id : "#toggleSpinButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_SPIN_TOGGLE },
                      { id : "#toggleArticlesButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_SHOW_DOCUMENTS },
                      { id : "#toggleHelpButton", key : 0, modifier : Utility.NO_KEY, type : Toolbar.EVENT_SHOW_HELP },
                    ]

   initialize : =>

      @setButtonSelected("#menuButton", true)
      @setButtonSelected("#infoButton", true)

      @setButtonSelected("#perspectiveButton", false)
      @setButtonSelected("#orthographicButton", false)
      @setButtonSelected("#dualButton", true)

      @setButtonSelected("#boxButton", true)
      @setButtonSelected("#viewportButton", true)

      @setButtonSelected("#selectButton", false)

      @setButtonSelected("#viewTopButton", true)
      @setButtonSelected("#viewFrontButton", false)
      @setButtonSelected("#viewSideButton", false)

      @setButtonSelected("#spinLeftButton", false)
      @setButtonSelected("#spinStopButton", true)
      @setButtonSelected("#spinRightButton", false)

      @setHelpModal("#toggleHelpButton")

      #@setButtonSelected("#animateButton", true)
      #@setButtonSelected("#animateSpinButton", true)


   setButtonSelected : (id, selected) =>

      color = Palette.BUTTON.getStyle()
      if selected then color = Palette.BUTTON_SELECTED.getStyle()

      $(id).css('color', color)


   blinkButton : (id) =>

      @setButtonSelected(id, true)
      window.setTimeout(@unblinkButton, 200, id)


   unblinkButton : (id) =>
   
      #console.log "Toolbar.unblinkButton " + id
      @setButtonSelected(id, false)


   setMenuButtonSelected : (selected) =>

      @setButtonSelected("#menuButton", selected)


   setInfoButtonSelected : (selected) =>

      @setButtonSelected("#infoButton", selected)


   setCameraButtonSelected : (selected1, selected2, selected3) =>

      @setButtonSelected("#perspectiveButton", selected1)
      @setButtonSelected("#orthographicButton", selected2)
      @setButtonSelected("#dualButton", selected3)


   blinkResetButton : =>
   
      @blinkButton("#resetButton")


   blinkClearButton : =>
   
      @blinkButton("#clearButton")


   setBoxButtonSelected : (selected) =>

      @setButtonSelected("#boxButton", selected)


   setViewportButtonSelected : (selected) =>

      @setButtonSelected("#viewportButton", selected)


   setSelectButtonSelected : (selected) =>

      @setButtonSelected("#selectButton", selected)


   setViewButtonSelected : (selected1, selected2, selected3) =>

      @setButtonSelected("#viewTopButton", selected1)
      @setButtonSelected("#viewFrontButton", selected2)
      @setButtonSelected("#viewSideButton", selected3)


   setSpinButtonSelected : (selected1, selected2, selected3) =>

      @setButtonSelected("#spinLeftButton", selected1)
      @setButtonSelected("#spinStopButton", selected2)
      @setButtonSelected("#spinRightButton", selected3)


   setAnimateButtonSelected : (selected) =>

      @setButtonSelected("#animateButton", selected)

   setHelpModal : =>

       $('#myModal').modal 'show'

       $('p.toolTip_text').removeClass 'active'
       $('p.toolTip_text').first().addClass 'active'

       #console.log 'Loaded modal thingy.'

       $('.next-button').click =>
          $nextItem = $('p.toolTip_text.active').next()
          #console.log $nextItem.attr 'id'
          if $nextItem.is 'button'
             $('#myModal').modal 'hide'
             #$('.back-button').css 'display', 'none'
             $('.back-button').css 'visibility', 'hidden'
             $nextItem.prev().removeClass 'active'
             #$('p.first').addClass 'active'
          else
             $nextItem.addClass 'active'
             $nextItem.prev().removeClass 'active'
             #$('.back-button').css 'display', 'inline-block'
             $('.back-button').css 'visibility', 'visible'
          return

       $('.back-button').click =>
          $prevItem = $('p.toolTip_text.active').prev()
          if $prevItem.is 'div'
             #$('.back-button').css 'display', 'none'
             $('.back-button').css 'visibility', 'hidden'
          else
             $prevItem.addClass 'active'
             $prevItem.next().removeClass 'active'
          return

   showHelpModal : =>
    
      $('#myModal').modal 'show'

      $('p.toolTip_text').removeClass 'active'
      $('p.toolTip_text').first().addClass 'active'
             


module.exports = Toolbar
