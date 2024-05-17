package serializers.transformers;

import haxe.io.Bytes;

// example simple transformer - will encode / decode the serialization data to base64
class Base64 implements ITransformer {
    public function new() {
    }

    public function transformTo(input:String):String {
        return haxe.crypto.Base64.encode(Bytes.ofString(input));
    }

    public function transformFrom(input:String):String {
        return haxe.crypto.Base64.decode(input).toString();
    }

}