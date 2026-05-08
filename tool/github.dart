import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'yaml.dart';

String gitHubReleaseAsset({
  required String version,
  required String asset,
}) {
  return '${getPubspec().repository}/releases/download/$version/$asset';
}

Future<void> downloadFile(String url, String savePath) async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 404) {
    throw Exception(
      'Asset not found (404).'
      ' Check that the release tag and filename are correct.',
    );
  } else if (response.statusCode >= 400) {
    throw Exception(
      'HTTP Error ${response.statusCode} during download.',
    );
  }

  final file = File(savePath);
  await file.writeAsBytes(response.bodyBytes);
}

class GithubAsset {
  const GithubAsset({
    required this.url,
    required this.id,
    required this.name,
  });

  factory GithubAsset.fromJson(Map<String, dynamic> json) {
    return GithubAsset(
      url: json['url'] as String,
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final String url;
  final int id;
  final String name;

  @override
  String toString() {
    return 'GithubAsset(id: $id, url: $url, name:$name)';
  }
}

Future<Iterable<GithubAsset>> getReleaseAssets(String version) async {
  final repo = getPubspec().repository;
  final parts = repo.split('github.com/').last.split('/');
  final owner = parts[0];
  final repoName = parts[1];

  final url =
      'https://api.github.com/repos/$owner/$repoName/releases/tags/$version';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch release info: ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return (data['assets'] as List<dynamic>).map(
    (asset) => GithubAsset.fromJson(asset as Map<String, dynamic>),
  );
}
