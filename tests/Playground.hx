package;

import why.uploader.remote.GoogleCloudStorage.GoogleCloudStorageDestination;
import why.uploader.*;
import why.uploader.local.*;
import why.uploader.remote.*;
import why.uploader.recorder.*;

using tink.CoreApi;

class Playground {
	static function main() {
		final local = new Browser();
		final remote = new GoogleCloudStorage(o -> tink.Url.parse('gcs://${o.bucket}/${o.name}'));

		Manager.create(local, remote, BrowserRecorder.new).handle(o -> switch o {
			case Success(manager):
				manager.initiate('', {bucket: 'buck', name: 'path/to/file.jpg'}).next(upload -> {
					final progress = upload.start(); // Progress<Outcome<Noise, Error>>, will record progress to local storage
					final link = progress.handle(v -> {}); // cancel link to pause upload, handle the progress again to resume
					Noise;
				});

				final resumable = manager.stored[0]; // locally-stored unfinished uploads from previous sessions
				final progress = resumable.start(); // same as above
			case Failure(_):
		});
	}
}
