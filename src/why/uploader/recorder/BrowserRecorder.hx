package why.uploader.recorder;

import tink.Chunk;
import js.html.Storage;
import js.Browser.window;

using tink.CoreApi;

// TODO: use indexeddb to store large files
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

	public function record(upload:Upload<Src, Dest>, section:BigInt):Promise<Noise> {
		final id = upload.id;

		final sourceKey = '$prefix:$id:source';
		final destinationKey = '$prefix:$id:destination';
		final sectionKey = '$prefix:$id:section';
		final chunkSizeKey = '$prefix:$id:chunkSize';

		final fields = Reflect.fields(storage);

		final tasks = [];

		if (!fields.contains(sourceKey))
			tasks.push(upload.source.serialize().next(serialized -> {
				storage.setItem(sourceKey, serialized.toHex());
				Promise.NOISE;
			}));

		if (!fields.contains(destinationKey))
			storage.setItem(destinationKey, upload.destination.serialize().toHex());

		storage.setItem(sectionKey, '$section');
		storage.setItem(chunkSizeKey, '${upload.chunkSize}');

		return Promise.inParallel(tasks);
	}

	public function unrecord(upload:Upload<Src, Dest>):Promise<Noise> {
		final id = upload.id;
		storage.removeItem('$prefix:$id:source');
		storage.removeItem('$prefix:$id:destination');
		storage.removeItem('$prefix:$id:section');
		storage.removeItem('$prefix:$id:chunkSize');
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
				final section = storage.getItem('$prefix:$id:section'); // consider incorporating offset when serializing source (e.g. only serialize not-yet-uploaded part)
				final chunkSize = storage.getItem('$prefix:$id:chunkSize');

				switch [
					local.unserializeSource(Chunk.ofHex(source)),
					remote.unserializeDestination(Chunk.ofHex(destination)),
					Std.parseInt(section),
					Std.parseInt(chunkSize),
				] {
					case [Success(source), Success(destination), section, chunkSize] if (section != null && chunkSize != null):
						uploads.push(new Upload(id, this, source, destination, section, chunkSize));
					case _: // skip
				}
			}
		}
		return uploads;
	}
}
