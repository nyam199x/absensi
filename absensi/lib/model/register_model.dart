import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'register_model.g.dart';

RegisterModel registerModelFromJson(String str) => RegisterModel.fromJson(json.decode(str));

String registerModelToJson(RegisterModel data) => json.encode(data.toJson());

@JsonSerializable()
class RegisterModel {
    @JsonKey(name: "name")
    final String? name;
    @JsonKey(name: "email")
    final String? email;
    @JsonKey(name: "password")
    final String? password;

    RegisterModel({
        this.name,
        this.email,
        this.password,
    });

    factory RegisterModel.fromJson(Map<String, dynamic> json) => _$RegisterModelFromJson(json);

  get data => null;

  String? get message => null;

    Map<String, dynamic> toJson() => _$RegisterModelToJson(this);
}