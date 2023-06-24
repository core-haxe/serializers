package serializers;

interface ISerializable {
    function toString():String;
    function fromString(data:Any):Void;
}