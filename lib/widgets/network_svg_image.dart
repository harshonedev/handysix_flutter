import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class NetworkSvgImage extends StatelessWidget {
  final String imageUrl;

  const NetworkSvgImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FileInfo>(
      future: DefaultCacheManager().getFileFromCache(imageUrl).then((
        file,
      ) async {
        if (file == null) {
          return await DefaultCacheManager().downloadFile(imageUrl);
        }
        return file;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final file = snapshot.data!.file;
          return SvgPicture.file(file, fit: BoxFit.cover, );
        } else if (snapshot.hasError) {
          return const Icon(Icons.error);
        } else {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: const CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
