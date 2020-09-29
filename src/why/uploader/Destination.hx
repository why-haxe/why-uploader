package why.uploader;

import tink.Chunk;
import tink.http.Request;

using tink.CoreApi;

interface Destination {
	function range(offset:BigInt, length:BigInt, total:Option<BigInt>):Promise<OutgoingRequestHeader>;
	function serialize():Chunk;
}
