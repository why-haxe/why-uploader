package why.uploader;

using tink.CoreApi;

interface Recorder<Src, Dest> {
	function record(upload:Upload<Src, Dest>, offset:BigInt):Promise<Noise>;
	function unrecord(upload:Upload<Src, Dest>):Promise<Noise>;
	function retrieve():Promise<Array<Upload<Src, Dest>>>;
}
