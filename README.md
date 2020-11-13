# gstatem3
The state machine for Haxe.

The steps to make a new state machie, and please check test example for reference.

1. draw the UML with WhiteStarUml, and export with xmi format.
2. import the xmi file as resource in hxml.

Note:

1. the event will be autobuilt with sm.SMBuilder.buildEvent.
2. the state will be autobuilt with sm.SMBuilder.buildState.
3. the state machine will be autobuilt with sm.SMBuilder.buildSM.


License:
this project follows the Apache V2 license.
