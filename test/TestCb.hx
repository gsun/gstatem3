import TestMsg;

class TestCb {

  @:isVar public var sm(default, default) :sm.SM;
  @:isVar public var state(default, default) :String;
  
   
  public function new(s:String, sm:sm.SM) {
      this.state = s;
      this.sm = sm;
  }
  
  public function on(e:String, msg:TestMsg) {
      sm.processEvent(e, this, msg);
  }
   
  public function action1(msg:TestMsg) :Void {
      msg.path.push("action1");
  }
  
  public function action2(msg:TestMsg) :Void {
      msg.path.push("action2");
  }
  
  public function action3(msg:TestMsg) :Void {
      msg.path.push("action3");
  }
  
  public function action4(msg:TestMsg) :Void {
      msg.path.push("action4");
  }
  
  public function actionb(msg:TestMsg) :Void {
      msg.path.push("actionb");
  }
  
  public function entryc(msg:TestMsg) :Void {
      msg.path.push("entryc");
  }

  public function exitb(msg:TestMsg) :Void {
      msg.path.push("exitb");
  }
  
  public function exitc(msg:TestMsg) :Void {
      msg.path.push("exitc");
  }
  
  public function entryd(msg:TestMsg) :Void {
      msg.path.push("entryd");
  }

  public function exitd(msg:TestMsg) :Void {
      msg.path.push("exitd");
  }
  
  public function exiti(msg:TestMsg) :Void {
      msg.path.push("exiti");
  }
  
  public function entryf(msg:TestMsg) :Void {
      msg.path.push("entryf");
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