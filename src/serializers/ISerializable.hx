package serializers;

@:keep @:expose
interface ISerializable {
    function serialize():String;
    function unserialize(data:Any):Void;
}