// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionUser {

 String? get id; String? get name; String get dateOfBirth;
/// Create a copy of SessionUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionUserCopyWith<SessionUser> get copyWith => _$SessionUserCopyWithImpl<SessionUser>(this as SessionUser, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SessionUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionUser&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.dateOfBirth, _this.dateOfBirth) || other.dateOfBirth == _this.dateOfBirth));
}


@override
int get hashCode {
  final _this = this as SessionUser;
  return Object.hash(runtimeType,_this.id,_this.name,_this.dateOfBirth);
}

@override
String toString() {
  final _this = this as SessionUser;
  return 'SessionUser(id: ${_this.id}, name: ${_this.name}, dateOfBirth: ${_this.dateOfBirth})';
}


}

/// @nodoc
abstract mixin class $SessionUserCopyWith<$Res>  {
  factory $SessionUserCopyWith(SessionUser value, $Res Function(SessionUser) _then) = _$SessionUserCopyWithImpl;
@useResult
$Res call({
 String? id, String? name, String dateOfBirth
});




}
/// @nodoc
class _$SessionUserCopyWithImpl<$Res>
    implements $SessionUserCopyWith<$Res> {
  _$SessionUserCopyWithImpl(this._self, this._then);

  final SessionUser _self;
  final $Res Function(SessionUser) _then;

/// Create a copy of SessionUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = freezed,Object? dateOfBirth = null,}) {
  return _then(SessionUser(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionUser].
extension SessionUserPatterns on SessionUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionUser value)  $default,){
final _that = this;
switch (_that) {
case _SessionUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionUser value)?  $default,){
final _that = this;
switch (_that) {
case _SessionUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? name,  String dateOfBirth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionUser() when $default != null:
return $default(_that.id,_that.name,_that.dateOfBirth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? name,  String dateOfBirth)  $default,) {final _that = this;
switch (_that) {
case _SessionUser():
return $default(_that.id,_that.name,_that.dateOfBirth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? name,  String dateOfBirth)?  $default,) {final _that = this;
switch (_that) {
case _SessionUser() when $default != null:
return $default(_that.id,_that.name,_that.dateOfBirth);case _:
  return null;

}
}

}

/// @nodoc


class _SessionUser implements SessionUser {
  const _SessionUser({this.id, this.name, required this.dateOfBirth});
  

@override final  String? id;
@override final  String? name;
@override final  String dateOfBirth;

/// Create a copy of SessionUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionUserCopyWith<_SessionUser> get copyWith => __$SessionUserCopyWithImpl<_SessionUser>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,dateOfBirth);
}

@override
String toString() {
    return 'SessionUser(id: $id, name: $name, dateOfBirth: $dateOfBirth)';
}


}

/// @nodoc
abstract mixin class _$SessionUserCopyWith<$Res> implements $SessionUserCopyWith<$Res> {
  factory _$SessionUserCopyWith(_SessionUser value, $Res Function(_SessionUser) _then) = __$SessionUserCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? name, String dateOfBirth
});




}
/// @nodoc
class __$SessionUserCopyWithImpl<$Res>
    implements _$SessionUserCopyWith<$Res> {
  __$SessionUserCopyWithImpl(this._self, this._then);

  final _SessionUser _self;
  final $Res Function(_SessionUser) _then;

/// Create a copy of SessionUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = freezed,Object? dateOfBirth = null,}) {
  return _then(_SessionUser(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SessionState {

 bool get initialized; bool get hasSession; bool get verified; bool get connectionFailed; bool? get smsSent; String? get phone; EligibilityDecision? get eligibility; SessionUser? get user;
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStateCopyWith<SessionState> get copyWith => _$SessionStateCopyWithImpl<SessionState>(this as SessionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionState&&(identical(other.initialized, _this.initialized) || other.initialized == _this.initialized)&&(identical(other.hasSession, _this.hasSession) || other.hasSession == _this.hasSession)&&(identical(other.verified, _this.verified) || other.verified == _this.verified)&&(identical(other.connectionFailed, _this.connectionFailed) || other.connectionFailed == _this.connectionFailed)&&(identical(other.smsSent, _this.smsSent) || other.smsSent == _this.smsSent)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.eligibility, _this.eligibility) || other.eligibility == _this.eligibility)&&(identical(other.user, _this.user) || other.user == _this.user));
}


@override
int get hashCode {
  final _this = this as SessionState;
  return Object.hash(runtimeType,_this.initialized,_this.hasSession,_this.verified,_this.connectionFailed,_this.smsSent,_this.phone,_this.eligibility,_this.user);
}

@override
String toString() {
  final _this = this as SessionState;
  return 'SessionState(initialized: ${_this.initialized}, hasSession: ${_this.hasSession}, verified: ${_this.verified}, connectionFailed: ${_this.connectionFailed}, smsSent: ${_this.smsSent}, phone: ${_this.phone}, eligibility: ${_this.eligibility}, user: ${_this.user})';
}


}

/// @nodoc
abstract mixin class $SessionStateCopyWith<$Res>  {
  factory $SessionStateCopyWith(SessionState value, $Res Function(SessionState) _then) = _$SessionStateCopyWithImpl;
@useResult
$Res call({
 bool initialized, bool hasSession, bool verified, bool connectionFailed, bool? smsSent, String? phone, EligibilityDecision? eligibility, SessionUser? user
});


$SessionUserCopyWith<$Res>? get user;

}
/// @nodoc
class _$SessionStateCopyWithImpl<$Res>
    implements $SessionStateCopyWith<$Res> {
  _$SessionStateCopyWithImpl(this._self, this._then);

  final SessionState _self;
  final $Res Function(SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? initialized = null,Object? hasSession = null,Object? verified = null,Object? connectionFailed = null,Object? smsSent = freezed,Object? phone = freezed,Object? eligibility = freezed,Object? user = freezed,}) {
  return _then(SessionState(
initialized: null == initialized ? _self.initialized : initialized // ignore: cast_nullable_to_non_nullable
as bool,hasSession: null == hasSession ? _self.hasSession : hasSession // ignore: cast_nullable_to_non_nullable
as bool,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,connectionFailed: null == connectionFailed ? _self.connectionFailed : connectionFailed // ignore: cast_nullable_to_non_nullable
as bool,smsSent: freezed == smsSent ? _self.smsSent : smsSent // ignore: cast_nullable_to_non_nullable
as bool?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,eligibility: freezed == eligibility ? _self.eligibility : eligibility // ignore: cast_nullable_to_non_nullable
as EligibilityDecision?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as SessionUser?,
  ));
}
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $SessionUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionState].
extension SessionStatePatterns on SessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionState value)  $default,){
final _that = this;
switch (_that) {
case _SessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionState value)?  $default,){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool initialized,  bool hasSession,  bool verified,  bool connectionFailed,  bool? smsSent,  String? phone,  EligibilityDecision? eligibility,  SessionUser? user)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.initialized,_that.hasSession,_that.verified,_that.connectionFailed,_that.smsSent,_that.phone,_that.eligibility,_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool initialized,  bool hasSession,  bool verified,  bool connectionFailed,  bool? smsSent,  String? phone,  EligibilityDecision? eligibility,  SessionUser? user)  $default,) {final _that = this;
switch (_that) {
case _SessionState():
return $default(_that.initialized,_that.hasSession,_that.verified,_that.connectionFailed,_that.smsSent,_that.phone,_that.eligibility,_that.user);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool initialized,  bool hasSession,  bool verified,  bool connectionFailed,  bool? smsSent,  String? phone,  EligibilityDecision? eligibility,  SessionUser? user)?  $default,) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.initialized,_that.hasSession,_that.verified,_that.connectionFailed,_that.smsSent,_that.phone,_that.eligibility,_that.user);case _:
  return null;

}
}

}

/// @nodoc


class _SessionState implements SessionState {
  const _SessionState({this.initialized = false, this.hasSession = false, this.verified = false, this.connectionFailed = false, this.smsSent, this.phone, this.eligibility, this.user});
  

@override@JsonKey() final  bool initialized;
@override@JsonKey() final  bool hasSession;
@override@JsonKey() final  bool verified;
@override@JsonKey() final  bool connectionFailed;
@override final  bool? smsSent;
@override final  String? phone;
@override final  EligibilityDecision? eligibility;
@override final  SessionUser? user;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionStateCopyWith<_SessionState> get copyWith => __$SessionStateCopyWithImpl<_SessionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionState&&(identical(other.initialized, initialized) || other.initialized == initialized)&&(identical(other.hasSession, hasSession) || other.hasSession == hasSession)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.connectionFailed, connectionFailed) || other.connectionFailed == connectionFailed)&&(identical(other.smsSent, smsSent) || other.smsSent == smsSent)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.eligibility, eligibility) || other.eligibility == eligibility)&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode {
    return Object.hash(runtimeType,initialized,hasSession,verified,connectionFailed,smsSent,phone,eligibility,user);
}

@override
String toString() {
    return 'SessionState(initialized: $initialized, hasSession: $hasSession, verified: $verified, connectionFailed: $connectionFailed, smsSent: $smsSent, phone: $phone, eligibility: $eligibility, user: $user)';
}


}

/// @nodoc
abstract mixin class _$SessionStateCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory _$SessionStateCopyWith(_SessionState value, $Res Function(_SessionState) _then) = __$SessionStateCopyWithImpl;
@override @useResult
$Res call({
 bool initialized, bool hasSession, bool verified, bool connectionFailed, bool? smsSent, String? phone, EligibilityDecision? eligibility, SessionUser? user
});


@override $SessionUserCopyWith<$Res>? get user;

}
/// @nodoc
class __$SessionStateCopyWithImpl<$Res>
    implements _$SessionStateCopyWith<$Res> {
  __$SessionStateCopyWithImpl(this._self, this._then);

  final _SessionState _self;
  final $Res Function(_SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? initialized = null,Object? hasSession = null,Object? verified = null,Object? connectionFailed = null,Object? smsSent = freezed,Object? phone = freezed,Object? eligibility = freezed,Object? user = freezed,}) {
  return _then(_SessionState(
initialized: null == initialized ? _self.initialized : initialized // ignore: cast_nullable_to_non_nullable
as bool,hasSession: null == hasSession ? _self.hasSession : hasSession // ignore: cast_nullable_to_non_nullable
as bool,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,connectionFailed: null == connectionFailed ? _self.connectionFailed : connectionFailed // ignore: cast_nullable_to_non_nullable
as bool,smsSent: freezed == smsSent ? _self.smsSent : smsSent // ignore: cast_nullable_to_non_nullable
as bool?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,eligibility: freezed == eligibility ? _self.eligibility : eligibility // ignore: cast_nullable_to_non_nullable
as EligibilityDecision?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as SessionUser?,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $SessionUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
