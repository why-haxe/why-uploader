package why.uploader;

import tink.Chunk;
using tink.CoreApi;

interface Remote<DestinationSpec> {
	function makeDestination(v:DestinationSpec):Promise<Destination>;
	function unserializeDestination(v:Chunk):Outcome<Destination, Error>;
	function slug():String;
}
