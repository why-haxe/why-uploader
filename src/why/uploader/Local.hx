package why.uploader;

import tink.Chunk;
using tink.CoreApi;

interface Local<SourceSpec> {
	function makeSource(spec:SourceSpec):Source;
	function unserializeSource(v:Chunk):Outcome<Source, Error>;
	function slug():String;
}
