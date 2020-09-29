package why.uploader;

import tink.Chunk;
import tink.http.Request;

using tink.CoreApi;

interface Source {
	function size():Promise<Option<BigInt>>;
	function upload(offset:BigInt, length:BigInt, getHeader:(length:BigInt) -> Promise<OutgoingRequestHeader>):Progress<Outcome<Noise, Error>>;
	function serialize():Promise<Chunk>;
}
