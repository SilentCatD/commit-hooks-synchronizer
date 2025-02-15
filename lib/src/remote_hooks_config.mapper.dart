// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'remote_hooks_config.dart';

class RemoteHooksConfigMapper extends ClassMapperBase<RemoteHooksConfig> {
  RemoteHooksConfigMapper._();

  static RemoteHooksConfigMapper? _instance;
  static RemoteHooksConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RemoteHooksConfigMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'RemoteHooksConfig';

  static String _$gitUrl(RemoteHooksConfig v) => v.gitUrl;
  static const Field<RemoteHooksConfig, String> _f$gitUrl =
      Field('gitUrl', _$gitUrl, key: r'git-url');
  static String? _$ref(RemoteHooksConfig v) => v.ref;
  static const Field<RemoteHooksConfig, String> _f$ref =
      Field('ref', _$ref, opt: true);

  @override
  final MappableFields<RemoteHooksConfig> fields = const {
    #gitUrl: _f$gitUrl,
    #ref: _f$ref,
  };

  static RemoteHooksConfig _instantiate(DecodingData data) {
    return RemoteHooksConfig(
        gitUrl: data.dec(_f$gitUrl), ref: data.dec(_f$ref));
  }

  @override
  final Function instantiate = _instantiate;

  static RemoteHooksConfig fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RemoteHooksConfig>(map);
  }

  static RemoteHooksConfig fromJsonString(String json) {
    return ensureInitialized().decodeJson<RemoteHooksConfig>(json);
  }
}

mixin RemoteHooksConfigMappable {
  String toJsonString() {
    return RemoteHooksConfigMapper.ensureInitialized()
        .encodeJson<RemoteHooksConfig>(this as RemoteHooksConfig);
  }

  Map<String, dynamic> toJson() {
    return RemoteHooksConfigMapper.ensureInitialized()
        .encodeMap<RemoteHooksConfig>(this as RemoteHooksConfig);
  }

  RemoteHooksConfigCopyWith<RemoteHooksConfig, RemoteHooksConfig,
          RemoteHooksConfig>
      get copyWith => _RemoteHooksConfigCopyWithImpl(
          this as RemoteHooksConfig, $identity, $identity);
  @override
  String toString() {
    return RemoteHooksConfigMapper.ensureInitialized()
        .stringifyValue(this as RemoteHooksConfig);
  }

  @override
  bool operator ==(Object other) {
    return RemoteHooksConfigMapper.ensureInitialized()
        .equalsValue(this as RemoteHooksConfig, other);
  }

  @override
  int get hashCode {
    return RemoteHooksConfigMapper.ensureInitialized()
        .hashValue(this as RemoteHooksConfig);
  }
}

extension RemoteHooksConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RemoteHooksConfig, $Out> {
  RemoteHooksConfigCopyWith<$R, RemoteHooksConfig, $Out>
      get $asRemoteHooksConfig =>
          $base.as((v, t, t2) => _RemoteHooksConfigCopyWithImpl(v, t, t2));
}

abstract class RemoteHooksConfigCopyWith<$R, $In extends RemoteHooksConfig,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? gitUrl, String? ref});
  RemoteHooksConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _RemoteHooksConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RemoteHooksConfig, $Out>
    implements RemoteHooksConfigCopyWith<$R, RemoteHooksConfig, $Out> {
  _RemoteHooksConfigCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RemoteHooksConfig> $mapper =
      RemoteHooksConfigMapper.ensureInitialized();
  @override
  $R call({String? gitUrl, Object? ref = $none}) => $apply(FieldCopyWithData(
      {if (gitUrl != null) #gitUrl: gitUrl, if (ref != $none) #ref: ref}));
  @override
  RemoteHooksConfig $make(CopyWithData data) => RemoteHooksConfig(
      gitUrl: data.get(#gitUrl, or: $value.gitUrl),
      ref: data.get(#ref, or: $value.ref));

  @override
  RemoteHooksConfigCopyWith<$R2, RemoteHooksConfig, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _RemoteHooksConfigCopyWithImpl($value, $cast, t);
}
