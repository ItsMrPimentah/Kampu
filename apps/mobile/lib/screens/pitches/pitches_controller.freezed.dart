// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pitches_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PitchesState {

 List<PitchVenue> get data; String get query; FootballFormat? get format; SurfaceType? get surface; DateTime? get date; double get maxDistance; String? get selectedSlot; String? get retryMessage; bool get notified; Map<String, SlotState> get slotStates;
/// Create a copy of PitchesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PitchesStateCopyWith<PitchesState> get copyWith => _$PitchesStateCopyWithImpl<PitchesState>(this as PitchesState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PitchesState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PitchesState&&const DeepCollectionEquality().equals(other.data, _this.data)&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.surface, _this.surface) || other.surface == _this.surface)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.maxDistance, _this.maxDistance) || other.maxDistance == _this.maxDistance)&&(identical(other.selectedSlot, _this.selectedSlot) || other.selectedSlot == _this.selectedSlot)&&(identical(other.retryMessage, _this.retryMessage) || other.retryMessage == _this.retryMessage)&&(identical(other.notified, _this.notified) || other.notified == _this.notified)&&const DeepCollectionEquality().equals(other.slotStates, _this.slotStates));
}


@override
int get hashCode {
  final _this = this as PitchesState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.data),_this.query,_this.format,_this.surface,_this.date,_this.maxDistance,_this.selectedSlot,_this.retryMessage,_this.notified,const DeepCollectionEquality().hash(_this.slotStates));
}

@override
String toString() {
  final _this = this as PitchesState;
  return 'PitchesState(data: ${_this.data}, query: ${_this.query}, format: ${_this.format}, surface: ${_this.surface}, date: ${_this.date}, maxDistance: ${_this.maxDistance}, selectedSlot: ${_this.selectedSlot}, retryMessage: ${_this.retryMessage}, notified: ${_this.notified}, slotStates: ${_this.slotStates})';
}


}

/// @nodoc
abstract mixin class $PitchesStateCopyWith<$Res>  {
  factory $PitchesStateCopyWith(PitchesState value, $Res Function(PitchesState) _then) = _$PitchesStateCopyWithImpl;
@useResult
$Res call({
 List<PitchVenue> data, String query, FootballFormat? format, SurfaceType? surface, DateTime? date, double maxDistance, String? selectedSlot, String? retryMessage, bool notified, Map<String, SlotState> slotStates
});




}
/// @nodoc
class _$PitchesStateCopyWithImpl<$Res>
    implements $PitchesStateCopyWith<$Res> {
  _$PitchesStateCopyWithImpl(this._self, this._then);

  final PitchesState _self;
  final $Res Function(PitchesState) _then;

/// Create a copy of PitchesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? query = null,Object? format = freezed,Object? surface = freezed,Object? date = freezed,Object? maxDistance = null,Object? selectedSlot = freezed,Object? retryMessage = freezed,Object? notified = null,Object? slotStates = null,}) {
  return _then(PitchesState(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<PitchVenue>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as FootballFormat?,surface: freezed == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as SurfaceType?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,maxDistance: null == maxDistance ? _self.maxDistance : maxDistance // ignore: cast_nullable_to_non_nullable
as double,selectedSlot: freezed == selectedSlot ? _self.selectedSlot : selectedSlot // ignore: cast_nullable_to_non_nullable
as String?,retryMessage: freezed == retryMessage ? _self.retryMessage : retryMessage // ignore: cast_nullable_to_non_nullable
as String?,notified: null == notified ? _self.notified : notified // ignore: cast_nullable_to_non_nullable
as bool,slotStates: null == slotStates ? _self.slotStates : slotStates // ignore: cast_nullable_to_non_nullable
as Map<String, SlotState>,
  ));
}

}


/// Adds pattern-matching-related methods to [PitchesState].
extension PitchesStatePatterns on PitchesState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PitchesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PitchesState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PitchesState value)  $default,){
final _that = this;
switch (_that) {
case _PitchesState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PitchesState value)?  $default,){
final _that = this;
switch (_that) {
case _PitchesState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PitchVenue> data,  String query,  FootballFormat? format,  SurfaceType? surface,  DateTime? date,  double maxDistance,  String? selectedSlot,  String? retryMessage,  bool notified,  Map<String, SlotState> slotStates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PitchesState() when $default != null:
return $default(_that.data,_that.query,_that.format,_that.surface,_that.date,_that.maxDistance,_that.selectedSlot,_that.retryMessage,_that.notified,_that.slotStates);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PitchVenue> data,  String query,  FootballFormat? format,  SurfaceType? surface,  DateTime? date,  double maxDistance,  String? selectedSlot,  String? retryMessage,  bool notified,  Map<String, SlotState> slotStates)  $default,) {final _that = this;
switch (_that) {
case _PitchesState():
return $default(_that.data,_that.query,_that.format,_that.surface,_that.date,_that.maxDistance,_that.selectedSlot,_that.retryMessage,_that.notified,_that.slotStates);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PitchVenue> data,  String query,  FootballFormat? format,  SurfaceType? surface,  DateTime? date,  double maxDistance,  String? selectedSlot,  String? retryMessage,  bool notified,  Map<String, SlotState> slotStates)?  $default,) {final _that = this;
switch (_that) {
case _PitchesState() when $default != null:
return $default(_that.data,_that.query,_that.format,_that.surface,_that.date,_that.maxDistance,_that.selectedSlot,_that.retryMessage,_that.notified,_that.slotStates);case _:
  return null;

}
}

}

/// @nodoc


class _PitchesState extends PitchesState {
  const _PitchesState({required  List<PitchVenue> data, this.query = '', this.format, this.surface, this.date, this.maxDistance = 10, this.selectedSlot, this.retryMessage, this.notified = false,  Map<String, SlotState> slotStates = const {}}): _data = data,_slotStates = slotStates,super._();
  

 final  List<PitchVenue> _data;
@override List<PitchVenue> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}

@override@JsonKey() final  String query;
@override final  FootballFormat? format;
@override final  SurfaceType? surface;
@override final  DateTime? date;
@override@JsonKey() final  double maxDistance;
@override final  String? selectedSlot;
@override final  String? retryMessage;
@override@JsonKey() final  bool notified;
 final  Map<String, SlotState> _slotStates;
@override@JsonKey() Map<String, SlotState> get slotStates {
  if (_slotStates is EqualUnmodifiableMapView) return _slotStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slotStates);
}


/// Create a copy of PitchesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PitchesStateCopyWith<_PitchesState> get copyWith => __$PitchesStateCopyWithImpl<_PitchesState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PitchesState&&const DeepCollectionEquality().equals(other.data, _data)&&(identical(other.query, query) || other.query == query)&&(identical(other.format, format) || other.format == format)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.date, date) || other.date == date)&&(identical(other.maxDistance, maxDistance) || other.maxDistance == maxDistance)&&(identical(other.selectedSlot, selectedSlot) || other.selectedSlot == selectedSlot)&&(identical(other.retryMessage, retryMessage) || other.retryMessage == retryMessage)&&(identical(other.notified, notified) || other.notified == notified)&&const DeepCollectionEquality().equals(other.slotStates, _slotStates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),query,format,surface,date,maxDistance,selectedSlot,retryMessage,notified,const DeepCollectionEquality().hash(_slotStates));
}

@override
String toString() {
    return 'PitchesState(data: $data, query: $query, format: $format, surface: $surface, date: $date, maxDistance: $maxDistance, selectedSlot: $selectedSlot, retryMessage: $retryMessage, notified: $notified, slotStates: $slotStates)';
}


}

/// @nodoc
abstract mixin class _$PitchesStateCopyWith<$Res> implements $PitchesStateCopyWith<$Res> {
  factory _$PitchesStateCopyWith(_PitchesState value, $Res Function(_PitchesState) _then) = __$PitchesStateCopyWithImpl;
@override @useResult
$Res call({
 List<PitchVenue> data, String query, FootballFormat? format, SurfaceType? surface, DateTime? date, double maxDistance, String? selectedSlot, String? retryMessage, bool notified, Map<String, SlotState> slotStates
});




}
/// @nodoc
class __$PitchesStateCopyWithImpl<$Res>
    implements _$PitchesStateCopyWith<$Res> {
  __$PitchesStateCopyWithImpl(this._self, this._then);

  final _PitchesState _self;
  final $Res Function(_PitchesState) _then;

/// Create a copy of PitchesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? query = null,Object? format = freezed,Object? surface = freezed,Object? date = freezed,Object? maxDistance = null,Object? selectedSlot = freezed,Object? retryMessage = freezed,Object? notified = null,Object? slotStates = null,}) {
  return _then(_PitchesState(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<PitchVenue>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as FootballFormat?,surface: freezed == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as SurfaceType?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,maxDistance: null == maxDistance ? _self.maxDistance : maxDistance // ignore: cast_nullable_to_non_nullable
as double,selectedSlot: freezed == selectedSlot ? _self.selectedSlot : selectedSlot // ignore: cast_nullable_to_non_nullable
as String?,retryMessage: freezed == retryMessage ? _self.retryMessage : retryMessage // ignore: cast_nullable_to_non_nullable
as String?,notified: null == notified ? _self.notified : notified // ignore: cast_nullable_to_non_nullable
as bool,slotStates: null == slotStates ? _self._slotStates : slotStates // ignore: cast_nullable_to_non_nullable
as Map<String, SlotState>,
  ));
}


}

// dart format on
