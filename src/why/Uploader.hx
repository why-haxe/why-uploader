package why;

import tink.http.Request;
using tink.CoreApi;

interface Uploader<FileRep> {
	function upload(body:UploadBody<FileRep>):Progress<Outcome<Noise, Error>>;
}

// distinguish a file reference from a generic `Source`
// because on some platforms the former can be optimized
// e.g. on React Native a file can be uploaded natively without being read into the JS context
enum UploadBody<FileRep> {
	File(file:FileRep);
	// Source(source:RealSource);
}