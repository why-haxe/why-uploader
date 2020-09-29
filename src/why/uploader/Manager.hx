package why.uploader;

import haxe.ds.ReadOnlyArray;
import tink.CoreApi;

class Manager<Src, Dest> {
	public final stored:ReadOnlyArray<Upload<Src, Dest>>;

	final local:Local<Src>;
	final remote:Remote<Dest>;
	final recorder:Recorder<Src, Dest>;

	function new(local, remote, recorder, stored) {
		this.local = local;
		this.remote = remote;
		this.recorder = recorder;
		this.stored = stored;
	}

	public static function create<Src, Dest>(local:Local<Src>, remote:Remote<Dest>, makeRecorder:(local:Local<Src>, remote:Remote<Dest>) -> Recorder<Src, Dest>):Promise<Manager<Src, Dest>> {
		final recorder = makeRecorder(local, remote);
		return recorder.retrieve().next(stored -> new Manager(local, remote, recorder, stored));
	}

	public inline function initiate(source:Src, destination:Dest):Promise<Upload<Src, Dest>> {
		return remote.makeDestination(destination).next(destination -> new Upload('TODO:uuid', recorder, local.makeSource(source), destination, 0));
	}
}
