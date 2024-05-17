package serializers.macros;

typedef SerializerConfig = {
    var ?ignore:Array<String>;
    var ?transformers:Array<String>;
}