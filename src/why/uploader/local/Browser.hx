package why.uploader.local;

import tink.Chunk;
import tink.http.Request;

using tink.CoreApi;
using tink.io.Source.RealSourceTools;

private typedef SourceSpec = tink.io.Source.RealSource;

class Browser implements Local<SourceSpec> {
	public function new() {}

	public function makeSource(spec:SourceSpec) {
		return new BrowserSource(spec);
	}

	public function unserializeSource(v:Chunk):Outcome<Source, Error> {
		return Success(new BrowserSource(v));
	}

	public function slug():String {
		// perhaps FQCN can make sure uniqueness
		return 'browser';
	}
}

class BrowserSource implements Source {
	public final spec:SourceSpec;

	public function new(spec) {
		this.spec = spec;
	}

	public function size():Promise<Option<BigInt>> {
		return Promise.resolve(None);
	}

	public function upload(offset:BigInt, length:BigInt, getHeader:(length:BigInt) -> Promise<OutgoingRequestHeader>):Progress<Outcome<Noise, Error>> {
		return spec.skip(cast offset).limit(cast length).all().next(chunk -> {
			getHeader(chunk.length).next(header -> {
				Progress.make((progress, finish) -> {
					// TODO: upload via xhr

					null;
				});
			});
		});
	}

	public function serialize():Promise<Chunk> {
		return spec.all();
	}
}
