package serializers;

interface ISerializable {
    function serialize():String;
    function unserialize(data:Any):Void;
}