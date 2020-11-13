import TestMsg;

class TestCb {

  @:isVar public var sm(default, default) :sm.SM;
  @:isVar public var state(default, default) :String;
  public var path :Array<String>;
   
  public function new(s:String, sm:sm.SM) {
      this.state = s;
      this.sm = sm;
      this.path = new Array();
  }
  
  public function on(e:String, msg:TestMsg) {
      sm.processEvent(e, this, msg);
  }
   
  public function action1(msg:TestMsg) :Void {
      path.push("action1");
  }
  
  public function action2(msg:TestMsg) :Void {
      path.push("action2");
  }
  
  public function action3(msg:TestMsg) :Void {
      path.push("action3");
  }
  
  public function action4(msg:TestMsg) :Void {
      path.push("action4");
  }
  
  public function actionb(msg:TestMsg) :Void {
      path.push("actionb");
  }
  
  public function entryc() :Void {
      path.push("entryc");
  }

  public function exitb() :Void {
      path.push("exitb");
  }
  
  public function exitc() :Void {
      path.push("exitc");
  }
  
  public function entryd() :Void {
      path.push("entryd");
  }

  public function exitd() :Void {
      path.push("exitd");
  }
  
  public function exiti() :Void {
      path.push("exiti");
  }
  
  public function entryf() :Void {
      path.push("entryf");
  }

  public dynamic function guard1(msg:TestMsg) :Bool {
    return false;
  }

  public dynamic function guard2(msg:TestMsg) :Bool {
    return true;
  }

  public dynamic function guard3(msg:TestMsg) :Bool {
    return false;
  }
  
  public dynamic function guard4(msg:TestMsg) :Bool {
    return true;
  }
}