import sm.SM;

@:build(sm.SMBuilder.buildState("umltest"))
@:enum
abstract TestState(String) from String to String {}

@:build(sm.SMBuilder.buildEvent("umltest"))
@:enum
abstract TestEvent(String) from String to String {}

class TestSM  extends haxe.unit.TestCase {

    public function testSimple () {
        
        var sm:SM = sm.SMBuilder.buildSM("umltest");  
        
        //StateA Event1 guard1(false) 
        var cb = new TestCb(StateA, sm);        
        var msg = new TestMsg();
        cb.on(Event1, msg);
        assertEquals(cb.state, StateE);  
        assertEquals(msg.path.toString(), ["entryd","entryc"].toString());
        #if debug trace("---------------------------------------"); #end
        
        //StateA Event1 guard1(true) 
        cb = new TestCb(StateA, sm);
        cb.guard1 = function guard1(msg:TestMsg) : Bool {
            return true;
        }
        var msg = new TestMsg();
        cb.on(Event1, msg);
        assertEquals(cb.state, StateB);
        assertEquals(msg.path.toString(), [].toString());
        #if debug trace("---------------------------------------"); #end
        
        //StateA Event7 
        cb = new TestCb(StateA, sm);
        var msg = new TestMsg();
        cb.on(Event7, msg);
        assertEquals(cb.state, StateB);  
        assertEquals(msg.path.toString(), [].toString());
        #if debug trace("---------------------------------------"); #end

        //StateB Event3       
        cb = new TestCb(StateB, sm);
        var msg = new TestMsg();
        cb.on(Event3, msg);
        assertEquals(cb.state, StateB); 
        assertEquals(msg.path.toString(), ["actionb"].toString());
        #if debug trace("---------------------------------------"); #end
        
        //StateB Event2
        cb = new TestCb(StateB, sm);
        var msg = new TestMsg();
        cb.on(Event2, msg);
        assertEquals(cb.state, StateA);            
        assertEquals(msg.path.toString(), ["exitb"].toString());
        #if debug trace("---------------------------------------"); #end
 
        //StateE Event4 guard4(true)
        cb = new TestCb(StateE, sm);
        var msg = new TestMsg();
        cb.on(Event4, msg);
        assertEquals(cb.state, StateK); 
        assertEquals(msg.path.toString(), ["action4","action3"].toString());
        #if debug trace("---------------------------------------"); #end

        //StateE Event4 guard3(true)
        cb = new TestCb(StateE, sm);
        cb.guard4 = function guard4(msg:TestMsg) : Bool {
            return false;
        }
        cb.guard3 = function guard3(msg:TestMsg) : Bool {
            return true;
        }
        var msg = new TestMsg();
        cb.on(Event4, msg);
        assertEquals(cb.state, StateJ); 
        assertEquals(msg.path.toString(), ["action2"].toString());
        #if debug trace("---------------------------------------"); #end

        //StateE Event4
        cb = new TestCb(StateE, sm);
        cb.guard4 = function guard4(msg:TestMsg) : Bool {
            return false;
        }
        var msg = new TestMsg();
        cb.on(Event4, msg);
        assertEquals(cb.state, StateF); 
        assertEquals(msg.path.toString(), ["entryf"].toString());
        #if debug trace("---------------------------------------"); #end
        
        //StateE Event8
        cb = new TestCb(StateE, sm);
        var msg = new TestMsg();
        cb.on(Event8, msg);
        assertEquals(cb.state, StateA);
        assertEquals(msg.path.toString(), ["exitc","exitd"].toString());
        #if debug trace("---------------------------------------"); #end
  
        //StateF Event3
        cb = new TestCb(StateF, sm);        
        var msg = new TestMsg();
        cb.on(Event3, msg);
        assertEquals(cb.state, StateF);  
        assertEquals(msg.path.toString(), [].toString());
        #if debug trace("---------------------------------------"); #end
        
        //StateF Event5
        cb = new TestCb(StateF, sm);        
        var msg = new TestMsg();
        cb.on(Event5, msg);
        assertEquals(cb.state, StateE);  
        assertEquals(msg.path.toString(), ["action1"].toString());
        #if debug trace("---------------------------------------"); #end
        
        //StateF Event1 guard1(true)
        cb = new TestCb(StateF, sm);        
        var msg = new TestMsg();
        cb.on(Event1, msg);
        assertEquals(cb.state, StateJ); 
        assertEquals(msg.path.toString(), ["action2"].toString());
        #if debug trace("---------------------------------------"); #end

        //StateF Event1 guard1(false)
        cb = new TestCb(StateF, sm);      
        cb.guard2 = function guard2(msg:TestMsg) : Bool {
            return false;
        }        
        var msg = new TestMsg();
        cb.on(Event1, msg);
        assertEquals(cb.state, StateK); 
        assertEquals(msg.path.toString(), ["action3"].toString());
        #if debug trace("---------------------------------------"); #end
        
        //StateI Event8
        cb = new TestCb(StateK, sm);
        var msg = new TestMsg();
        cb.on(Event8, msg);
        assertEquals(cb.state, StateB);
        assertEquals(msg.path.toString(), ["exiti","exitc","exitd"].toString());
        #if debug trace("---------------------------------------"); #end
        
        //StateK Event6
        cb = new TestCb(StateK, sm);
        var msg = new TestMsg();
        cb.on(Event6, msg);
        assertEquals(cb.state, StateE);       
        assertEquals(msg.path.toString(), ["exiti"].toString());
        #if debug trace("---------------------------------------"); #end

    }
}