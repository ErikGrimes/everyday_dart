import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';

import '../../../lib/shared/patch/patch.dart';


class Observed extends Object with ObservableMixin {
  
  @observable
  String field1;
  String _field2;
  
  get field2 => _field2;
  
  set field2(String value){
    _field2 = this.notifyPropertyChange(const Symbol('field2'), _field2, value);
  }
   
}

main(){
  
  test('observes',_observes);
  
}

_observes(){
  var orig= new Observed();
   
  var observer = new ObjectPatchObserver(orig);
  
  //TODO Make sure the order of records is reasonable
  var listener = (crs){
    expect(crs.length, equals(2));
    expect(crs[0].path, equals('/field2'));
    expect(crs[1].path, equals('/field1'));
  };
  
  observer.changes.listen(expectAsync1(listener));
  
  orig.field1 = '1';
  orig.field2 = '2';
  
  Observable.dirtyCheck();
  
}