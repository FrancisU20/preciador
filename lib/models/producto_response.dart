import 'dart:convert';
import 'dart:typed_data'; 
import 'package:flutter/cupertino.dart';
 
class ProductosResponse {
  List<Producto> producto;
 
  ProductosResponse({
    required this.producto,
  });
 
  factory ProductosResponse.fromRawJson(String str) =>
      ProductosResponse.fromJson(json.decode(str));
 
  String toRawJson() => json.encode(toJson());
 
  factory ProductosResponse.fromJson(Map<String, dynamic> json) =>
      ProductosResponse(
        producto: List<Producto>.from(
            json["Producto"].map((x) => Producto.fromJson(x))),
      );
 
  Map<String, dynamic> toJson() => {
        "Producto": List<dynamic>.from(producto.map((x) => x.toJson())),
      };
 
  static List<Producto> getProductosFromJsonDecode(
      List<dynamic> jsonDecodeAPI) {
    List<Producto> resultado = [];
    for (var item in jsonDecodeAPI) {
      Producto producto = Producto(
        listaPrecios: item['ListaPrecios'] ?? "N/A",
        codArticulo: item['COD_ARTICULO'] ?? "N/A",
        descripcion: item['descripcion'] ?? "N/A",
        pvp: item['PVP'] ?? 0,
        pvc: item['PVC'] ?? 0,
        entero: item['entero'] ?? 0,
        fraccion: item['fraccion'] ?? 0,
        valorPos: item['valor_pos'] ?? 0,
        esMf: item['es_mf'] ?? "N/A",
        iva: item['Iva'] ?? "N/A",
        idclase: item['idclase'] ?? "N/A",
        idmarca: "${item['idmarca']?? "N/A"}",
        aplicaDsctos: item['aplicaDsctos'] ?? "N/A",
        tiene: item['TIENE'] ?? '',
        top: '',
        urlImagen: null,
        valorIVA: item['valorIVA'] ?? 0.0,
        imgBase64: null,
      );
      try {
        producto.urlImagen = NetworkImage(item['urlImagen']);
        //Convertir la cadena base64 a imagen
        Uint8List bytes = base64Decode(item['imgBase64']);
        producto.imgBase64 = MemoryImage(bytes);
      } catch (e) {
        producto.urlImagen = null;
      }
      resultado.add(producto);
    }
    return resultado;
  }
}
 
class Producto {
  String listaPrecios;
  String codArticulo;
  String descripcion;
  double pvp;
  double pvc;
  int entero;
  int fraccion;
  int valorPos;
  String esMf;
  String iva;
  String idclase;
  String? idmarca;
  String aplicaDsctos;
  String top;
  ImageProvider? urlImagen;
  String tiene;
  double valorIVA;
  ImageProvider? imgBase64;
 
  Producto({
    required this.listaPrecios,
    required this.codArticulo,
    required this.descripcion,
    required this.pvp,
    required this.pvc,
    required this.entero,
    required this.fraccion,
    required this.valorPos,
    required this.esMf,
    required this.iva,
    required this.idclase,
    required this.idmarca,
    required this.aplicaDsctos,
    required this.top,
    required this.urlImagen,
    required this.tiene,
    required this.valorIVA,
    required this.imgBase64,
  });
 
  factory Producto.fromRawJson(String str) =>
      Producto.fromJson(json.decode(str));
 
  String toRawJson() => json.encode(toJson());
 
  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        listaPrecios: json["ListaPrecios"] ?? '',
        codArticulo: json["COD_ARTICULO"] ?? '',
        descripcion: json["descripcion"] ?? '',
        pvp: json["PVP"]?.toDouble(),
        pvc: json["PVC"]?.toDouble(),
        entero: json["entero"],
        fraccion: json["fraccion"],
        valorPos: json["valor_pos"],
        esMf: json["es_mf"] ?? '',
        iva: json["Iva"] ?? '',
        idclase: json["idclase"] ?? '',
        idmarca: json["idmarca"] ?? '',
        aplicaDsctos: json["aplicaDsctos"] ?? '',
        top: json["TOP"] ?? '',
        urlImagen: json["urlImagen"] ?? '',
        tiene: json["TIENE"] ?? '',
        valorIVA: json["valorIVA"] ?? 0.0,
        imgBase64: json["imgBase64"] ?? '',
      );
 
  Map<String, dynamic> toJson() => {
        "ListaPrecios": listaPrecios,
        "COD_ARTICULO": codArticulo,
        "descripcion": descripcion,
        "PVP": pvp,
        "PVC": pvc,
        "entero": entero,
        "fraccion": fraccion,
        "valor_pos": valorPos,
        "es_mf": esMf,
        "Iva": iva,
        "idclase": idclase,
        "idmarca": idmarca,
        "aplicaDsctos": aplicaDsctos,
        "TOP": top,
        "urlImagen": urlImagen,
        "TIENE": tiene,
        "valorIVA": valorIVA,
        "imgBase64": imgBase64,
      };
}
 