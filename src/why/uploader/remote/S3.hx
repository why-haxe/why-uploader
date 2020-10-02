package why.uploader.remote;

import tink.Chunk;
import tink.http.Header.HeaderField;
import tink.http.Request;
import tink.Url;
import tink.Anon.merge;
import why.uploader.Remote;

using tink.CoreApi;

typedef S3Path = {
	final bucket:String;
	final path:String;
}

private typedef S3Upload = S3Path & {
	final uploadId:String;
}

typedef S3UploadPart = S3Upload & {
	final partNumber:Int;
}

class S3 implements Remote<S3Path> {
	final initiateUpload:S3Path->Promise<String>; // returns upload id
	final getSignedRequest:S3UploadPart->Promise<OutgoingRequestHeader>;

	public function new(initiateUpload, getSignedRequest) {
		this.initiateUpload = initiateUpload;
		this.getSignedRequest = getSignedRequest;
	}

	public function makeDestination(path:S3Path):Promise<Destination> {
		return initiateUpload(path).next(uploadId -> (new S3Destination(merge(path, uploadId = uploadId), getSignedRequest) : Destination));
	}

	public function unserializeDestination(v:Chunk):Outcome<Destination, Error> {
		return tink.Json.parse((v : S3Upload)).map(upload -> (new S3Destination(upload, getSignedRequest) : Destination));
	}

	public function slug():String {
		// perhaps FQCN can make sure uniqueness
		return 's3';
	}
}

class S3Destination implements Destination {
	public final id:String;
	public final upload:S3Upload;

	final getSignedRequest:S3UploadPart->Promise<OutgoingRequestHeader>;

	public function new(upload, getSignedRequest) {
		this.upload = upload;
		this.id = upload.uploadId;
		this.getSignedRequest = getSignedRequest;
	}

	public function range(partNumber:Int, offset:BigInt, length:BigInt, total:Option<BigInt>):Promise<OutgoingRequestHeader> {
		return getSignedRequest(merge(upload, partNumber = partNumber));
	}

	public function serialize():Chunk {
		return tink.Json.stringify(upload);
	}
}
