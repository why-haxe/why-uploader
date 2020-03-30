package ; 

import js.Browser.*;
using tink.CoreApi;

class RunTests {

  static function main() {
    var input = document.createInputElement();
    input.type = 'file';
    input.onchange = function() {
      var file = input.files[0];
      trace(file.name);
      var header = new tink.http.Request.OutgoingRequestHeader(POST, 'https://httpbin.org/anything', []);
      var js = new why.uploader.JsUploader(header, true);
      var progress = js.upload(File(file));
      progress.listen(v -> trace(v.normalize().map(v -> v.toPercentageString(1))));
      progress.handle(v -> trace(v));
      
    }
    
    document.body.appendChild(input);
  }
  
}