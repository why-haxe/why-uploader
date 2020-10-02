package why.uploader;

using tink.CoreApi;

class Upload<Src, Dest> {
	public final id:String;
	public final source:Source;
	public final destination:Destination;
	public final chunkSize:Int;

	final recorder:Recorder<Src, Dest>;
	final initialSection:Int;

	public function new(id, recorder, source, destination, initialSection, chunkSize) {
		this.id = id;
		this.recorder = recorder;
		this.source = source;
		this.destination = destination;
		this.initialSection = initialSection;
		this.chunkSize = chunkSize;
	}

	public function start():Progress<Outcome<Noise, {error:Error, resumable:Upload<Src, Dest>}>> {
		recorder.record(this, 0).eager();
		var currentSection = initialSection;

		final progress:Progress<Outcome<Noise, Error>> = source.size().next(total -> {
			Progress.make((_progress, finish) -> {
				var binding:CallbackLink = null;

				inline function progress(v)
					_progress(v, total);

				(function next(section:Int) {
					currentSection = section; // store for error reporting
					final offset:BigInt = section * chunkSize;
					var chunkTotal:BigInt = chunkSize;
					final chunkProgress = source.upload(section, chunkSize,
						actualSize -> destination.range(section, offset, chunkTotal = actualSize,
							total.orTry(actualSize < chunkSize ? Some(offset + actualSize) : None)));

					binding = [
						chunkProgress.listen(v -> {
							final bytesUploaded = offset + v.value;
							recorder.record(this, bytesUploaded).eager();
							progress(bytesUploaded);
						}),

						chunkProgress.handle(o -> switch o {
							case Success(_):
								if (chunkTotal < chunkSize) {
									recorder.unrecord(this).eager();
									finish(Success(Noise));
								} else {
									final bytesUploaded = offset + chunkTotal;
									recorder.record(this, bytesUploaded).eager();
									progress(bytesUploaded);
									next(section + 1);
								}
							case Failure(e):
								// TODO: consider retrying this chunk
								finish(Failure(e));
						}),
					];
				})(initialSection);

				() -> binding.cancel();
			});
		});

		return progress.map(result -> switch result {
			case Success(_): Success(Noise);
			case Failure(e): Failure({error: e, resumable: clone(currentSection)});
		});
	}

	inline function clone(initialSection:Int) {
		return new Upload(id, recorder, source, destination, initialSection, chunkSize);
	}
}
