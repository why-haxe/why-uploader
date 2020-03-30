package why.uploader;

import js.html.XMLHttpRequest;
import js.html.File;
import tink.http.Request;
import tink.http.clients.JsClient;
import why.Uploader;

using tink.CoreApi;

class JsUploader implements Uploader<File> {
	final header:OutgoingRequestHeader;
	final withCredentials:Bool;
	
	public function new(header, withCredentials = false, ?isSuccess) {
		this.header = header;
		this.withCredentials = withCredentials;
		if(isSuccess != null) this.isSuccess = isSuccess;
	}
	
	public function upload(body:UploadBody<File>):Progress<Outcome<Noise, Error>> {
		return Progress.make(function(progress, finish) {
			
			var xhr = new XMLHttpRequest();
			xhr.open(header.method, header.url);
			xhr.withCredentials = withCredentials;
			// xhr.responseType = ARRAYBUFFER;
			for(field in header) 
			switch field.name {
				case CONTENT_LENGTH | HOST: // browsers doesn't allow setting these headers explicitly
				case _: xhr.setRequestHeader(field.name, field.value);
			}
			
			xhr.upload.onprogress = function(e) progress(e.loaded, e.lengthComputable ? Some(e.total) : None);
			xhr.onerror = function(e) finish(Failure(Error.withData(502, 'XMLHttpRequest Error', {error: e})));
			xhr.onload = function() isSuccess(xhr).handle(finish);
			
			switch body {
				case File(file): xhr.send(file);
			}
		});
	}
	
	dynamic function isSuccess(xhr:XMLHttpRequest):Promise<Noise> {
		return xhr.status >= 200 && xhr.status < 300 ? Promise.NOISE : Promise.reject(new Error(xhr.status, xhr.statusText));
	}
}