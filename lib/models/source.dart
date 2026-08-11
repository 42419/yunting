/// 对应 server/service/factory.go 里 GetDefaultSourceNames() 能搜歌的那几个平台。
/// label 是中文全名(跟后端 GetSourceDescription 保持一致)，short 是筛选 chip 上
/// 显示的短名——电台预设按钮位置有限，放不下"网易云音乐"这种四五个字。
class MusicSource {
  final String id;
  final String label;
  final String short;

  const MusicSource({required this.id, required this.label, required this.short});

  static const all = <MusicSource>[
    MusicSource(id: 'netease', label: '网易云音乐', short: '网易云'),
    MusicSource(id: 'qq', label: 'QQ音乐', short: 'QQ音乐'),
    MusicSource(id: 'kugou', label: '酷狗音乐', short: '酷狗'),
    MusicSource(id: 'kuwo', label: '酷我音乐', short: '酷我'),
    MusicSource(id: 'migu', label: '咪咕音乐', short: '咪咕'),
    MusicSource(id: 'qianqian', label: '千千音乐', short: '千千'),
    MusicSource(id: 'soda', label: '汽水音乐', short: '汽水'),
  ];

  static String labelOf(String id) {
    for (final s in all) {
      if (s.id == id) return s.label;
    }
    return id;
  }

  static String shortOf(String id) {
    for (final s in all) {
      if (s.id == id) return s.short;
    }
    return id;
  }
}
