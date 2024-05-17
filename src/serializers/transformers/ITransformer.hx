package serializers.transformers;

interface ITransformer {
    public function transformTo(input:String):String;
    public function transformFrom(input:String):String;
}