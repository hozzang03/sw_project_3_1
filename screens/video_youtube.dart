// video_youtube.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// 비디오 화면 import (필요 시)

class VideoYoutube extends StatelessWidget {
  final String videoId;
  final String thumbnailUrl;
  final String title;
  final String channelTitle;
  final int viewCount;
  final int likeCount;
  final List<Map<String, dynamic>> relatedVideos;

  const VideoYoutube({
    super.key,
    required this.videoId,
    required this.thumbnailUrl,
    required this.title,
    required this.channelTitle,
    required this.viewCount,
    required this.likeCount,
    required this.relatedVideos,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 관련 동영상 처리, null 체크
    final filteredRelatedVideos =
        relatedVideos.where((video) => video['id']?['videoId'] != videoId).toList();

    return Scaffold(
      appBar: AppBar(
        // 백 버튼 추가
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context); // 이전 화면으로 돌아가기
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 동영상 정보 섹션
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      'https://cors-anywhere.herokuapp.com/https://i.ytimg.com/vi/$videoId/hqdefault.jpg', // CORS 프록시 적용
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          channelTitle,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text('조회수 ${_formatCount(viewCount)} '),
                        const SizedBox(height: 4),
                        Text('좋아요 ${_formatCount(likeCount)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 영상 재생 텍스트
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D00),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  '영상 재생창',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // 영상 재생 섹션 (YouTube Iframe API 사용)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri("https://www.youtube.com/embed/$videoId")),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      javaScriptEnabled: true, // JavaScript 활성화
                    ),
                  ),
                ),
              ),
            ),

            // 관련 동영상 텍스트
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFAA2C),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  '관련 동영상',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // 관련 동영상 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 16 / 9,
                ),
                itemCount: filteredRelatedVideos.length > 4 ? 4 : filteredRelatedVideos.length, // 4개까지만 표시
                itemBuilder: (context, index) {
                  final video = filteredRelatedVideos[index];
                  final thumbnailUrl = 'https://cors-anywhere.herokuapp.com/https://i.ytimg.com/vi/${video['id']?['videoId']}/hqdefault.jpg'; // CORS 프록시 적용
                  final videoTitle = video['snippet']?['title'] ?? '제목 없음'; // null 체크 추가
                  final relatedVideoId = video['id']?['videoId'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      if (relatedVideoId.isNotEmpty) { // videoId가 비어있지 않은 경우에만 이동
                        // 다른 영상 재생창으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoYoutube(
                              videoId: relatedVideoId,
                              thumbnailUrl: thumbnailUrl,
                              title: videoTitle,
                              channelTitle: video['snippet']?['channelTitle'] ?? '채널 이름 없음', // null 체크 추가
                              viewCount: int.tryParse(video['viewCount'] ?? '0') ?? 0,
                              likeCount: int.tryParse(video['likeCount'] ?? '0') ?? 0,
                              relatedVideos: relatedVideos, // 동일 검색 결과 전달
                            ),
                          ),
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
