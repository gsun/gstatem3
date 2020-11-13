class Test {
    static function main(){
        var r = new haxe.unit.TestRunner();
        r.add(new TestSM());
        r.run();
    }
}