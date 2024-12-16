// title_youtube.dart

import 'package:flutter/material.dart';
import 'package:jibbap/screens/search_youtube.dart';
import '../services/youtube_api_service.dart'; // YouTube API 서비스 클래스
import 'video_youtube.dart'; // 영상 재생 화면

class TitleYoutube extends StatefulWidget {
  const TitleYoutube({super.key});

  @override
  _TitleYoutubeState createState() => _TitleYoutubeState();
}

class _TitleYoutubeState extends State<TitleYoutube> {
  final YouTubeApiService apiService = YouTubeApiService();
  late Future<Map<String, List<Map<String, dynamic>>>> _combinedFuture;

  @override
  void initState() {
    super.initState();
    _combinedFuture = _fetchHotAndRecommended();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchHotAndRecommended() async {
    // 1. HOT 레시피 가져오기
    final hotVideos = await apiService.fetchHotRecipes('간단 레시피');

    // 2. HOT 레시피의 videoId 추출
    final excludedVideoIds = hotVideos.map((video) => video['id']['videoId'] as String).toList();

    // 3. 오늘의 메뉴 추천 가져오기 (HOT 레시피 제외)
    final recommendedVideos = await apiService.fetchRecommendedMenus(
      '자취 레시피',
      excludedVideoIds: excludedVideoIds,
    );

    return {
      'hot': hotVideos,
      'recommended': recommendedVideos,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Back 버튼
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context); // 이전 화면으로 돌아가기
          },
        ),
        backgroundColor: Colors.white, // AppBar 배경 흰색
        elevation: 0, // 그림자 제거
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
        child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _combinedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final hotVideos = snapshot.data?['hot'] ?? [];
              final recommendedVideos = snapshot.data?['recommended'] ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 검색바
                  const SizedBox(height: 16),
                  TextField(
                    onSubmitted: (query) {
                      // 검색어 입력 후 Enter 키를 누르면 검색 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchYoutube(query: query), // 검색 결과 화면
                        ),
                      );
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: '검색',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200], // Colors.grey[10]은 존재하지 않으므로 수정
                    ),
                  ),
                  const SizedBox(height: 12), // 검색과 HOT 레시피 사이

                  // HOT 레시피 섹션
                  const Text(
                    'HOT 레시피',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // HOT 레시피 박스
                  Container(
                    height: 240,
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: hotVideos.isEmpty
                        ? const Center(child: Text('영상 데이터를 불러올 수 없습니다.'))
                        : GestureDetector(
                            onTap: () {
                              final video = hotVideos.first;
                              final thumbnailUrl =
                                  'https://cors-anywhere.herokuapp.com/https://i.ytimg.com/vi/${video['id']['videoId']}/hqdefault.jpg';

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoYoutube(
                                    videoId: video['id']['videoId'] ?? '',
                                    thumbnailUrl: thumbnailUrl,
                                    title: video['snippet']['title'] ?? '제목 없음',
                                    channelTitle: video['snippet']['channelTitle'] ?? '채널 이름 없음',
                                    viewCount: int.tryParse(video['viewCount'] ?? '0') ?? 0,
                                    likeCount: int.tryParse(video['likeCount'] ?? '0') ?? 0,
                                    relatedVideos: hotVideos,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      'https://cors-anywhere.herokuapp.com/https://i.ytimg.com/vi/${hotVideos.first['id']['videoId']}/hqdefault.jpg',
                                      width: double.infinity,
                                      height: 160, // 이미지 크기 조정
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image, size: 108, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hotVideos.first['snippet']['title'] ?? '제목 없음',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  hotVideos.first['snippet']['channelTitle'] ?? '채널 이름 없음',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // 오늘의 메뉴 추천 섹션
                  const Text(
                    '오늘의 메뉴 추천',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: recommendedVideos.isEmpty
                        ? const Center(child: Text('영상 데이터를 불러올 수 없습니다.'))
                        : ListView.builder(
                            itemCount: recommendedVideos.length,
                            itemBuilder: (context, index) {
                              final video = recommendedVideos[index];
                              final thumbnailUrl =
                                  'https://cors-anywhere.herokuapp.com/https://i.ytimg.com/vi/${video['id']['videoId']}/hqdefault.jpg';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoYoutube(
                                        videoId: video['id']['videoId'] ?? '',
                                        thumbnailUrl: thumbnailUrl,
                                        title: video['snippet']['title'] ?? '제목 없음',
                                        channelTitle: video['snippet']['channelTitle'] ?? '채널 이름 없음',
                                        viewCount: int.tryParse(video['viewCount'] ?? '0') ?? 0,
                                        likeCount: int.tryParse(video['likeCount'] ?? '0') ?? 0,
                                        relatedVideos: recommendedVideos,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  padding: const EdgeInsets.all(8.0),
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8.0),
                                        child: Image.network(
                                          thumbnailUrl,
                                          width: 100,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              video['snippet']['title'] ?? '제목 없음',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              video['snippet']['channelTitle'] ?? '채널 이름 없음',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
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
                          ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
