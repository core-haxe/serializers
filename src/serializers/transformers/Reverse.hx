package serializers.transformers;

// example simple transformer - will reverse the serialization data
class Reverse implements ITransformer {
    public function new() {
    }

    public function transformTo(input:String):String {
        return reverseString(input);
    }

    public function transformFrom(input:String):String {
        return reverseString(input);
    }

    private static function reverseString(s:String):String {
        var s2 = new StringBuf();
        for (i in -s.length+1...1) {
            s2.addChar(s.charCodeAt(-i)); 
        }
        return s2.toString();
    }
}