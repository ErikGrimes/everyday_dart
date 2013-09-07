library everyday.patch.serialization;

import 'package:serialization/serialization.dart';
import 'patch.dart';


configure(Serialization serialization){
  serialization.addRule(new _PropertyPatchRecordRule());
  serialization.addRule(new _ListPatchRecordRule());
}


class _PropertyPatchRecordRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == PropertyPatchRecord;
  getState(instance) => [instance.path, instance.value];
  create(state) => new PropertyPatchRecord(state[0], state[1]);
  setState(PropertyPatchRecord a, List state) => {};
}

class _ListPatchRecordRule extends CustomRule {
  bool appliesTo(instance, Writer w) => instance.runtimeType == ListPatchRecord;
  getState(instance) => [instance.path, instance.index, instance.addedCount, instance.removedCount, instance.values];
  create(state) => new ListPatchRecord(state[0], state[1], state[2], state[3], state[4]);
  setState(ListPatchRecord a, List state) => {};
}

