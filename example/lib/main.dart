import 'package:flutter/material.dart';

import 'video_detail_page.dart';
import 'video_item.dart';

export 'video_item.dart' show kDemoVideoUrl;

void main() {
  runApp(const VideoDemandDemoApp());
}

class VideoDemandDemoApp extends StatelessWidget {
  const VideoDemandDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '生活灵感',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF28766B),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF222222),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const VideoListPage(),
    );
  }
}

class VideoListPage extends StatelessWidget {
  const VideoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('生活灵感')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double coverWidth = (constraints.maxWidth - 36) / 2;
                final TextScaler scaler = MediaQuery.textScalerOf(context);
                final double textHeight =
                    scaler.scale(16) * 1.4 * 2 + scaler.scale(12) * 1.5 + 36;
                return GridView.builder(
                  key: const PageStorageKey<String>('video-list'),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: coverWidth + textHeight,
                  ),
                  itemCount: demoVideos.length,
                  itemBuilder: (BuildContext context, int index) {
                    final VideoItem video = demoVideos[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => VideoDetailPage(video: video),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SizedBox(
                              height: coverWidth,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  Image.network(
                                    video.coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const ColoredBox(
                                      color: Color(0xFFE5E9E7),
                                      child: Center(
                                        child: Icon(Icons.image_outlined,
                                            color: Color(0xFF70837B), size: 36),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const Icon(Icons.play_arrow,
                                                size: 16, color: Colors.white),
                                            const SizedBox(width: 3),
                                            Text(video.duration,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                              child: Text(
                                video.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF222222),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.account_circle_outlined,
                                      size: 20, color: Color(0xFF65716C)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      video.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: Color(0xFF65716C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
