package why.uploader.remote;

import tink.Chunk;
import tink.http.Header.HeaderField;
import tink.http.Request;
import tink.Url;
import why.uploader.Remote;

using tink.CoreApi;

typedef GoogleCloudStoragePath = {
	final bucket:String;
	final name:String;
}

class GoogleCloudStorage implements Remote<GoogleCloudStoragePath> {
	final getSessionUri:GoogleCloudStoragePath->Promise<Url>;

	public function new(getSessionUri) {
		this.getSessionUri = getSessionUri;
	}

	public function makeDestination(name:GoogleCloudStoragePath):Promise<Destination> {
		return getSessionUri(name).next(uri -> (new GoogleCloudStorageDestination(uri) : Destination));
	}

	public function unserializeDestination(v:Chunk):Outcome<Destination, Error> {
		return Success(new GoogleCloudStorageDestination(v.toString()));
	}

	public function slug():String {
		// perhaps FQCN can make sure uniqueness
		return 'google-cloud-storage';
	}
}

class GoogleCloudStorageDestination implements Destination {
	public final id:String;
	public final sessionUri:Url;

	public function new(sessionUri) {
		this.id = this.sessionUri = sessionUri;
	}

	public function range(_:Int, offset:BigInt, length:BigInt, total:Option<BigInt>):Promise<OutgoingRequestHeader> {
		final first = offset;
		final last = offset + length - 1;
		final total = switch total {
			case Some(v): '$v';
			case None: '*';
		}

		return new OutgoingRequestHeader(PUT, sessionUri, [
			new HeaderField(CONTENT_LENGTH, '$length'),
			new HeaderField(CONTENT_RANGE, 'bytes $first-$last/$total'),
		]);
	}

	public function serialize():Chunk {
		return sessionUri.toString();
	}
}
