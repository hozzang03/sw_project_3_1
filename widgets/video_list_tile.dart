import 'package:flutter/material.dart';
import '../screens/video_youtube.dart';

class VideoListTile extends StatelessWidget {
  final String videoId;
  final String thumbnailUrl;
  final String title;
  final String channelTitle;

  const VideoListTile({
    super.key,
    required this.videoId,
    required this.thumbnailUrl,
    required this.title,
    required this.channelTitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // 썸네일 이미지 표시
      leading: Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 80,
            color: Colors.white, // 대체 배경
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
          );
        },
      ),
      title: Text(title), // 동영상 제목
      subtitle: Text(channelTitle), // 채널 이름
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoYoutube(
              videoId: videoId,
              thumbnailUrl: thumbnailUrl,
              title: title,
              channelTitle: channelTitle,
              viewCount: 0, // 임시로 기본값 설정
              likeCount: 0, // 임시로 기본값 설정
              relatedVideos: const [], // 관련 동영상은 비어 있는 리스트로 전달
            ), // 동영상 재생 화면으로 이동
          ),
        );
      },
    );
  }
}
