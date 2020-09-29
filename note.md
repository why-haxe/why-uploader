1. init a local (RN / JS)
3. init manager with the local
3. init a transport (S3 / GCS)

new upload
1. ask manager to initialize an upload of a file with a particular transport
2. call upload() on the request and watch the progress
3. the request is cancellable and pausable
4. if paused, tell manager to save in its list
5. upload is by-chunk (chunk size configurable), and progress is stored in manager

resume upload
1. resumable uploads can be listed by manager
2. call upload() on the request and watch the progress (so the request should store enough info for a resume)





# local
- handle file retrieval
- get chunk of file

# transport
handle http transport, i.e. initialization and resume mechanism 