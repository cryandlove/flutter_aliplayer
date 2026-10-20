/// 演示条目共用测试流，封面、文案和时长仅用于列表展示。
const String kDemoVideoUrl = 'https://v.douyin.com/0qIDevzQOws/';

class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.duration,
    this.videoUrl = kDemoVideoUrl,
  });

  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String duration;
  final String videoUrl;
}

const List<VideoItem> demoVideos = <VideoItem>[
  VideoItem(
    id: 'bedroom',
    title: '无主灯卧室，越住越喜欢',
    author: '林一的家',
    coverUrl: 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=85',
    duration: '00:46',
  ),
  VideoItem(
    id: 'smart-home',
    title: '全屋智能入住半年的感受',
    author: '陈同学',
    coverUrl: 'https://images.unsplash.com/photo-1558002038-1055907df827?w=800&q=85',
    duration: '01:28',
  ),
  VideoItem(
    id: 'dining-room',
    title: '餐厅的氛围感，藏在灯光里',
    author: '小满的日常',
    coverUrl: 'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=800&q=85',
    duration: '00:58',
  ),
  VideoItem(
    id: 'living-room',
    title: '回家后的第一件事，打开观影模式',
    author: '阿哲',
    coverUrl: 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=800&q=85',
    duration: '01:12',
  ),
  VideoItem(
    id: 'lighting',
    title: '一盏灯，让家多一点温柔',
    author: '慢慢生活',
    coverUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=800&q=85',
    duration: '00:36',
  ),
  VideoItem(
    id: 'home',
    title: '理想中的家，是舒服自在',
    author: '可可的家',
    coverUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&q=85',
    duration: '01:06',
  ),
];
