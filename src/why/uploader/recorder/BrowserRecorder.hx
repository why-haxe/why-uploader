package why.uploader.recorder;

import tink.Chunk;
import js.html.Storage;
import js.Browser.window;

using tink.CoreApi;

class BrowserRecorder<Src, Dest> implements Recorder<Src, Dest> {
	final storage:Storage;
	final local:Local<Src>;
	final remote:Remote<Dest>;
	final prefix:String;

	public function new(local, remote) {
		this.storage = window.localStorage;
		this.local = local;
		this.remote = remote;
		this.prefix = 'why-uploader:${local.slug()}:${remote.slug()}';
	}

	public function record(upload:Upload<Src, Dest>, offset:BigInt):Promise<Noise> {
		final id = upload.id;

		final sourceKey = '$prefix:$id:source';
		final destinationKey = '$prefix:$id:destination';
		final offsetKey = '$prefix:$id:offset';

		final fields = Reflect.fields(storage);

		final tasks = [];

		if (!fields.contains(sourceKey))
			tasks.push(upload.source.serialize().next(serialized -> {
				storage.setItem(sourceKey, serialized.toHex());
				Promise.NOISE;
			}));

		if (!fields.contains(destinationKey))
			storage.setItem(destinationKey, upload.destination.serialize().toHex());

		storage.setItem(offsetKey, '$offset');

		return Promise.inParallel(tasks);
	}

	public function unrecord(upload:Upload<Src, Dest>):Promise<Noise> {
		final id = upload.id;
		storage.removeItem('$prefix:$id:source');
		storage.removeItem('$prefix:$id:destination');
		storage.removeItem('$prefix:$id:offset');
		return Promise.NOISE;
	}

	public function retrieve():Promise<Array<Upload<Src, Dest>>> {
		final uploads = [];

		// source can fail to store, so we check it
		final regex = new EReg('${EReg.escape(prefix)}:(.*):source', '');

		for (key in Reflect.fields(storage)) {
			if (regex.match(key)) {
				final id = regex.matched(1);
				final source = storage.getItem('$prefix:$id:source');
				final destination = storage.getItem('$prefix:$id:destination');
				final offset = storage.getItem('$prefix:$id:offset'); // consider incorporating offset when serializing source (e.g. only serialize not-yet-uploaded part)

				switch [
					local.unserializeSource(Chunk.ofHex(source)),
					remote.unserializeDestination(Chunk.ofHex(destination)),
					Std.parseFloat(offset)
				] {
					case [Success(source), Success(destination), offset] if (!Math.isNaN(offset)):
						uploads.push(new Upload(id, this, source, destination, offset));
					case _: // skip
				}
			}
		}
		return uploads;
	}
}
