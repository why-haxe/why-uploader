package why.uploader;

using tink.CoreApi;

class Upload<Src, Dest> {
	public final id:String;
	public final source:Source;
	public final destination:Destination;

	final recorder:Recorder<Src, Dest>;
	final initialOffset:BigInt;

	public function new(id, recorder, source, destination, initialOffset) {
		this.id = id;
		this.recorder = recorder;
		this.source = source;
		this.destination = destination;
		this.initialOffset = initialOffset;
	}

	public function start():Progress<Outcome<Noise, {error:Error, resumable:Upload<Src, Dest>}>> {
		var currentOffset = initialOffset;
		var chunkSize:BigInt = 50 * 256 * 1024; // TODO: paramterize

		recorder.record(this, 0).eager();
		final progress:Progress<Outcome<Noise, Error>> = source.size().next(total -> {
			(Progress.make((_progress, finish) -> {
				var binding:CallbackLink = null;

				inline function progress(v)
					_progress(v, total);

				(function next() {
					var chunkTotal = chunkSize;
					final chunkProgress = source.upload(currentOffset, chunkSize,
						actualSize -> destination.range(currentOffset, chunkTotal = actualSize,
							total.orTry(actualSize < chunkSize ? Some(currentOffset + actualSize) : None)));

					binding = [
						chunkProgress.listen(v -> {
							final bytesUploaded = currentOffset + v.value;
							recorder.record(this, bytesUploaded).eager();
							progress(bytesUploaded);
						}),

						chunkProgress.handle(o -> switch o {
							case Success(_):
								if (chunkTotal < chunkSize) {
									recorder.unrecord(this).eager();
									finish(Success(Noise));
								} else {
									final bytesUploaded = currentOffset + chunkTotal;
									recorder.record(this, bytesUploaded).eager();
									progress(bytesUploaded);
									next();
								}
							case Failure(e):
								// TODO: consider retrying this chunk
								finish(Failure(e));
						}),
					];
				})();

				() -> binding.cancel();
			}) : Progress<Outcome<Noise, Error>>);
		});

		return progress.map(result -> switch result {
			case Success(_): Success(Noise);
			case Failure(e): Failure({error: e, resumable: clone(currentOffset)});
		});
	}

	inline function clone(initialOffset:BigInt) {
		return new Upload(id, recorder, source, destination, initialOffset);
	}
}
