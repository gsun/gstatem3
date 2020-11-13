package sm;

import sys.FileSystem;
import sys.io.File;

private typedef StateItem = {
    name:String,      //state name, which must be defined in UML and is used within state ENUM generation.
    container:String, //upper state.
    incoming:String,  //incmoing transition list.
    outgoing:String,  //outgoing transition list.
    simple:Bool,      //state without children states.
    term:Bool,       //the terminate state.
    pseudo:Bool,      //stereotype defined by user, also should be simple.
}

private typedef TransItem = {
    name:String,     //transiton name, can be ignored in UML.
    source:String,   //source state id.
    target:String,   //target state id.
}

private typedef EventItem = {
    name:String,     //event name, which must be defined in UML and is used within event ENUM generation.
    transId:String,  //transition belonging to.
}

enum ActionType {
    entry;
    exit;
    guard;
    trans;
}

private typedef ActionItem = {
    name:String,     //the function name for entry/exit/guard/action.
    actionType:ActionType,
    stateId:String,  //valid if entry or exit action.
    transId:String,  //valid if gurad or normal action.
}

private typedef StateHierarchy = {
    compositeStates:Array<String>,  //composite states list from low to high level.
    atomState:String,               //state without upper state except "TOP" in UML.
}

private typedef Behavior = {
    description:String,
    transit:String,  
    entryExit:String,    
    nextState:String, //state after transit, and state before entry/exit.
} 

private typedef FlattenedTransItem = {
    description:String,
    source:String,              //name of source state.
    target:String,              //name of target state. 
    event:String,               //name of event.
    guard:String,           //guard function.
    behaviors:Array<Behavior>,  //behavior list.
    flattenedLevel:Int,       //the level from composite state to atom state.
}

private typedef TransPriorityItem = {
    transId:String,
    flattenedLevel:Int, //level 0: simple state; level 1: one upper level...
    target:String,
    event:String,
    guard:String,
} 

class UmlParser {

    static var umlParsers:Map<String,UmlParser> = new Map();
    
    /***********original data parsed from xml file*****************************/
    public var stateDetails:Map<String, StateItem>;       //index:state id
    public var transDetails:Map<String, TransItem>;       //index:transition id
    public var eventDetails:Map<String, EventItem>;       //index:event id
    public var actionDetails:Map<String, ActionItem>;     //index:action id
    
    /**********intermediate date generated from original data***************/
    public var stateHierarchy:Map<String, Array<StateHierarchy>>;   //index:state id
    public var parentStates:Map<String, Array<String>>;             //index:state id
    
    /**********the result of translation*************************/
    public var flattenedTransDetails:Map<String, FlattenedTransItem>; //index:transition id(original+flattened from composite state)
    public var vertics:Map<String, Array<TransPriorityItem>>;         //vertices with sorted transitions.
    
    public static function findUmlParser(resourceName:String) :UmlParser {
        //check if the parser is already existing
        var parser = umlParsers.get(resourceName);
        if (parser != null) return parser;
        
        var content = haxe.Resource.getString(resourceName);        
        if (content == null) {
            SM.err("\nresource file " + resourceName + " not exist!");
        }

        parser = new UmlParser();
        umlParsers.set(resourceName, parser);
        parser.parse(Xml.parse(content).firstElement());
        parser.audit();
        parser.translate();
        parser.sortVertixTransitions();
        

        #if debug
        parser.toString();
        #end

        return parser;
    }
    
    function logState(e:Xml) {
        var id = e.get("xmi.id");
        var name = e.get("name");
        var container = e.get("container");
        var incoming = e.get("incoming");
        var outgoing = e.get("outgoing");
        var simple = (e.nodeName == "UML:SimpleState") ? true:false;
        var term = (e.nodeName == "UML:FinalState") ? true:false;  
        
        stateDetails.set(id,  { name:name, 
                                container:container, 
                                incoming:incoming, 
                                outgoing:outgoing,
                                simple:simple,
                                term:term,
                                pseudo:false});
        
    }
    
    function logTransition(e:Xml) {
        var id = e.get("xmi.id");
        var name = e.get("name");
        var source = e.get("source");
        var target = e.get("target");

        transDetails.set(id,  { name:name, 
                                source:source, 
                                target:target});
    }
    
    function logEvent(e:Xml) {
        var id = e.get("xmi.id");
        var name = e.get("name");
        var transition = e.get("transition");

        eventDetails.set(id,  { name:name, 
                                transId:transition });
    }
    
    function logStereotype(e:Xml) {
        var name = e.get("name");
        var element = e.get("extendedElement");
        
        if (name  == "pseudostate" || name == "pseudo") {
            for (el in element.split(" ")) {
                    var stateDetail = stateDetails.get(el);
                if (stateDetail != null) {
                    stateDetail.pseudo = true;
                    stateDetails.set(el, stateDetail);
                }
            }
        }
    }
    
    function logAction(e:Xml) {
        var id = e.get("xmi.id");
        var name = e.get("name");
        var actionType:ActionType = ActionType.trans;
        var stateId=null;
        var transId=null;
        
        //some trick process depend on the xml export from WhiteStarUml version 5.4.5.0.
        if (e.parent.nodeName == "UML:State.entry") {
            actionType = ActionType.entry;
            stateId = e.parent.parent.get("xmi.id");            
        }   
        else if (e.parent.nodeName == "UML:State.exit") {
            actionType = ActionType.exit;
            stateId = e.parent.parent.get("xmi.id");
        }       
        else if (e.nodeName == "UML:BooleanExpression") {
            name = e.get("body"); //guard body contain the action name
            actionType = ActionType.guard;
            transId = e.parent.parent.get("transition");
        }
        else {
            transId = e.parent.parent.parent.parent.get("xmi.id");      //normal action
        }

        actionDetails.set(id,  { name:name, 
                                 actionType:actionType,
                                 stateId:stateId,
                                 transId:transId});
    }
    
    
    public function parse(e:Xml) {
        
        
        for (ii in e.elements()) {
        
             switch (ii.nodeName) {
                 case "UML:SimpleState", "UML:FinalState", "UML:CompositeState":
                     logState(ii);                   
                 case "UML:Transition":
                     logTransition(ii);
                 case "UML:SignalEvent":
                     logEvent(ii);           
                 case "UML:UninterpretedAction", "UML:BooleanExpression":
                     logAction(ii);
                 case "UML:Stereotype":
                     logStereotype(ii);
             }
             
             if (ii.firstElement() == null) continue;  //lowest level
             
             parse(ii);
       }
    }
    
    function findEventName(transId:String):String {
        var eventName:String = null;
        for (ii in eventDetails.keys()) {
            var eventDetail = eventDetails.get(ii);
            if (eventDetail != null && 
                eventDetail.transId == transId) {
                eventName = eventDetail.name;
                break;
            }
        }
        return eventName;
    }
    
    function findActionName(id:String, actionType:ActionType):String {
        var action:String = null;
        for (ii in actionDetails.keys()) {
            var actionDetail = actionDetails.get(ii);
            if (actionDetail != null && 
                (actionDetail.transId == id ||
                 actionDetail.stateId == id) && 
                actionDetail.actionType == actionType) {
                action = actionDetail.name;
                break;
            }
        }
        return action;
    }
    
    function findStateName(stateId:String):String {
        var stateDetail = stateDetails.get(stateId);
        if (stateDetail == null) SM.err('\nState(' + stateId + ')has no name configured');
        return stateDetail.name;
    }
    
    function findBehaviors(transId:String, source:String, target:String) {
        var behaviors:Array<Behavior> = [];
                
        var allSourceParents = parentStates.get(source);
        var allTargetParents = parentStates.get(target);
        
        //check if source and target have the same parent state.
        var sourceParents:Array<String> = allSourceParents.copy();
        var targetParents:Array<String> = allTargetParents.copy();
        
        for (ii in 0...allSourceParents.length) {
             var jj = allTargetParents.indexOf(allSourceParents[ii]);
             if (jj == -1) continue;
             sourceParents = (ii == 0)? []:allSourceParents.slice(0,ii);
             targetParents = (jj == 0)? []:allTargetParents.slice(0,jj);
             break;
        }
        
        //the original is from low to high level, reverse it.
        targetParents.reverse();
        
        if (source != target) {
            //source exit
            behaviors.push({  description:'exiting ' + findStateName(source),
                              transit:null,
                              entryExit:findActionName(source, ActionType.exit), 
                              nextState:findStateName(source),});       
            //source parent composite state exit
            for (parent in sourceParents) {
                behaviors.push({  description:'exiting ' + findStateName(parent),
                                  transit:null,
                                  entryExit:findActionName(parent, ActionType.exit), 
                                  nextState:findStateName(parent),});
            }        
        }
        //transit
        //target has parent states, so transit to the highest parent state.
        var nextStateId = (targetParents[0] != null) ? targetParents[0]:target;     
        behaviors.push({  description:'transit ' + findStateName(nextStateId),
                          transit:findActionName(transId, ActionType.trans),
                          entryExit:null,    
                          nextState:findStateName(nextStateId),});
        
        if (source != target) {        
            //target parent composite state entry
            for (parent in targetParents) {
                behaviors.push({  description:'entering ' + findStateName(parent),
                                  transit:null,
                                  entryExit:findActionName(parent, ActionType.entry),    
                                  nextState:findStateName(parent),});
            }
            //target entry
            behaviors.push({  description:'entering ' + findStateName(target),
                              transit:null,
                              entryExit:findActionName(target, ActionType.entry),    
                              nextState:findStateName(target),});       
        }
        return behaviors;
    }
    
    function findSubStates(ancestor:String, composite:Array<String>=null) :Array<StateHierarchy> {
        var subStates:Array<StateHierarchy> = [];
        var inComposites:Array<String> = (composite==null) ? []:composite;
        for (stateId in stateDetails.keys()) {
            var stateItem:StateItem = stateDetails.get(stateId);
            if (stateItem.container != ancestor) continue;
            if (stateItem.simple == true || 
                stateItem.term == true) {
                subStates.push( {  compositeStates:inComposites.copy(),
                                   atomState:stateId });
            }
            else {
                var compoistes:Array<String> = inComposites.copy();
                compoistes.push(stateId);  //log the composite state
                subStates = subStates.concat(findSubStates(stateId, compoistes));
            }
        }
        return subStates;
    }
    
    function audit() {

        for (transId in transDetails.keys()) {
            var transDetail = transDetails.get(transId);
            
            if (transDetail == null) SM.err('\nAudit Failure: can not find the transition details with transition id $transId');
            if (transDetail.source == null) SM.err('\nAudit Failure: no source configured with state id $transId');
            if (transDetail.target == null) SM.err('\nAudit Failure: no target configured with state id $transId');
            
            var sourceStateDetail = stateDetails.get(transDetail.source);
            if (sourceStateDetail == null) SM.err('\nAudit Failure: can not find the state details with state id $transDetail.source');
            if (sourceStateDetail.name == null) SM.err('\nAudit Failure: no name configured with state id $transDetail.source');    
            
            var targetStateDetail = stateDetails.get(transDetail.target);
            if (targetStateDetail == null) SM.err('\nAudit Failure: can not find the state details with state id $transDetail.target');
            if (targetStateDetail.name == null) SM.err('\nAudit Failure: no name configured with state id $transDetail.target');
            if (targetStateDetail.simple != true && targetStateDetail.term != true) {
                SM.err('\nAudit Failure: none atom state with target name $targetStateDetail.name');
            }
        }
        
        for (eventId in eventDetails.keys()) {
            var eventDetail = eventDetails.get(eventId);
            if (eventDetail == null) SM.err('\nAudit Failure: can not find the event details with event id $eventId');
            if (eventDetail.name == null) SM.err('\nAudit Failure: no name configured with event id $eventId' + eventId);
            if (eventDetail.transId == null) SM.err('\nAudit Failure: no transition configured with event id $eventId'  + eventId);
            
            var transDetail = transDetails.get(eventDetail.transId);
            if (transDetail == null) SM.err('\nAudit Failure: can not find the transition details with event name $eventDetail.name and transition id $eventDetail.transId');
        }
        
        for (actionId in actionDetails.keys()) {
            var actionDetail = actionDetails.get(actionId);
            if (actionDetail == null) SM.err('\nAudit Failure: can not find the action details with action id $actionId');
            if (actionDetail.name == null) SM.err('\nAudit Failure: no name configured with action id $actionId');
            if (actionDetail.transId == null && actionDetail.stateId == null) SM.err('\nAudit Failure: no transition or state configured with action name $actionDetail.name');
            if (actionDetail.transId != null && actionDetail.stateId != null) SM.err('\nAudit Failure: both transition and state configured with action name $actionDetail.name');
            
            if (actionDetail.transId != null) {
                var transDetail = transDetails.get(actionDetail.transId);
                if (transDetail == null) SM.err('\nAudit Failure: can not find the transition details with action name $actionDetail.name and transition id $actionDetail.transId');
            }
            
            if (actionDetail.stateId != null) {
                var stateDetail = stateDetails.get(actionDetail.stateId);
                if (stateDetail == null) SM.err('\nAudit Failure: can not find the transition details with action name $actionDetail.name and state id $actionDetail.stateId');
            }
            
        }
    }
    
    function translate() {          
        for (stateId in stateDetails.keys()) {
            var subStates:Array<StateHierarchy> = findSubStates(stateId);
            stateHierarchy.set(stateId, subStates);
        }
        
        for (item in stateHierarchy) {
            for (subState in item) {
                 var parent:Array<String> = parentStates.get(subState.atomState);
                 var composites:Array<String> = (subState.compositeStates==null) ? []:subState.compositeStates.copy();
                 if (parent == null || 
                     parent.length < composites.length) {                     
                     composites.reverse(); //upstream
                     parentStates.set(subState.atomState, composites);                              
                 }               
            }            
        }
        
        //derive the transition from composite state to simple state.
        for (transId in transDetails.keys()) {
            var transDetail = transDetails.get(transId);
            var stateItem:StateItem = stateDetails.get(transDetail.source);
            var event = findEventName(transId);
            var guard = findActionName(transId, ActionType.guard);
            
            if (stateItem.simple == true) { 
                var behaviors = findBehaviors(transId, transDetail.source,transDetail.target);
                var source = findStateName(transDetail.source);
                var target = findStateName(transDetail.target);
                var description = source + ':' + event + '/' + guard;
                                            
                flattenedTransDetails.set(transId, { description:description,
                                                     source:source,
                                                     target:target,
                                                     flattenedLevel:0,
                                                     event:event,
                                                     guard:guard,
                                                     behaviors:behaviors});
                continue;
            }
            
            var subStates:Array<StateHierarchy> = stateHierarchy.get(transDetail.source);
            var ii=0;
            for (substate in subStates) {               
                var behaviors = findBehaviors(transId, substate.atomState, transDetail.target);
                var source = findStateName(substate.atomState);
                var target = findStateName(transDetail.target);
                var description = stateItem.name + ':' + event + '/' + guard;
                
                var flattenedTransId = transId + '.' + ii++;                                
                flattenedTransDetails.set(flattenedTransId, {  description:description,
                                                               source:source,
                                                               target:target, 
                                                               flattenedLevel:substate.compositeStates.length+1,
                                                               event:event,
                                                               guard:guard,
                                                               behaviors:behaviors});
            }                       
        }
    }
    
    function sortPriority(a:TransPriorityItem, b:TransPriorityItem):Int {   
        if (a.event != b.event) return (a.event > b.event) ? -1:1;
        if (a.guard != null && b.guard == null) return -1;
        if (a.guard == null && b.guard != null) return 1;
        if (a.flattenedLevel != b.flattenedLevel) return (a.flattenedLevel < b.flattenedLevel) ? -1:1;
        if (a.target != b.target) return (a.target > b.target) ? -1:1;  
        return 0;
    }
    
    function sortVertixTransitions() {
        for (stateId in stateDetails.keys()) {
            var stateDetail = stateDetails.get(stateId);
            
            //add term as vertix for destructor in runtime
            if (stateDetail.term == true) {
                vertics.set(stateId, []);
                continue;
            }
            
            if (stateDetail.simple == false) continue;
            
            var transPriority:Array<TransPriorityItem> = [];        

            for (transId in flattenedTransDetails.keys()) {
                var transDetail = flattenedTransDetails.get(transId);

                if (transDetail.source == stateDetail.name) {                    
                     transPriority.push({ transId:transId,
                                          target:transDetail.target,
                                          flattenedLevel:transDetail.flattenedLevel,
                                          guard:transDetail.guard,
                                          event:transDetail.event});                                             
                }
            }
            
            transPriority.sort(sortPriority);
            
            vertics.set(stateId, transPriority);
        }
    
    }
    
    public function new() {
        stateDetails = new Map();
        transDetails = new Map();
        flattenedTransDetails = new Map();
        eventDetails = new Map();
        actionDetails = new Map();  
        stateHierarchy = new Map();
        parentStates = new Map();
        vertics = new Map();
    }
    
    public function toString() :Void {
        var infos:Array<Map<String, Dynamic>> = [stateDetails,transDetails,flattenedTransDetails,eventDetails,
                                                 actionDetails,stateHierarchy,parentStates,vertics];
        for (info in infos) {
            for (key in info.keys()) trace(key + " " + info[key]);
        }
    }
}