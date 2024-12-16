// search_youtube.dart

import 'package:flutter/material.dart';
import '../services/youtube_api_service.dart';
import 'video_youtube.dart'; // VideoYoutube 화면 import

class SearchYoutube extends StatefulWidget {
  final String query;

  const SearchYoutube({super.key, required this.query});

  @override
  _SearchYoutubeState createState() => _SearchYoutubeState();
}

class _SearchYoutubeState extends State<SearchYoutube> {
  final apiService = YouTubeApiService();
  int currentPage = 1; // 현재 페이지 번호
  static const int itemsPerPage = 5; // 페이지당 최대 동영상 수
  late String searchQuery;

  @override
  void initState() {
    super.initState();
    searchQuery = widget.query; // 초기 검색어 설정
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Column(
        children: [
          // 검색창 추가
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onSubmitted: (query) {
                setState(() {
                  searchQuery = query; // 검색어 업데이트
                  currentPage = 1; // 페이지 초기화
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '검색어를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[10],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft, // 왼쪽 정렬
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                '< $searchQuery >',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: apiService.searchFilteredVideos(searchQuery), // 필터링된 메서드 호출
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final videos = snapshot.data!;
                  if (videos.isEmpty) {
                    return const Center(child: Text('조건에 맞는 동영상이 없습니다.'));
                  }

                  // 현재 페이지에 해당하는 동영상 계산
                  final totalPages = (videos.length / itemsPerPage).ceil();
                  final startIndex = (currentPage - 1) * itemsPerPage;
                  final endIndex = (startIndex + itemsPerPage > videos.length)
                      ? videos.length
                      : startIndex + itemsPerPage;
                  final currentVideos = videos.sublist(startIndex, endIndex);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: currentVideos.length,
                          itemBuilder: (context, index) {
                            final video = currentVideos[index];
                            // 썸네일 URL 처리: CORS 프록시를 통해 URL을 수정
                            final thumbnailUrl = 'https://cors-anywhere.herokuapp.com/https://i.ytimg.com/vi/${video['id']['videoId']}/hqdefault.jpg';
                            
                            return GestureDetector(
                              onTap: () {
                                // 영상 클릭 시 VideoYoutube 화면으로 이동
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoYoutube(
                                      videoId: video['id']['videoId'],
                                      thumbnailUrl: thumbnailUrl,
                                      title: video['snippet']['title'] ?? '제목 없음', // null 체크 추가
                                      channelTitle: video['snippet']['channelTitle'] ?? '채널 이름 없음', // null 체크 추가
                                      viewCount: int.tryParse(video['viewCount'] ?? '0') ?? 0,
                                      likeCount: int.tryParse(video['likeCount'] ?? '0') ?? 0,
                                      relatedVideos: videos, // 동일 검색 결과 전달
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                padding: const EdgeInsets.all(8.0),
                                height: 130, // 블록 높이 고정
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
                                        thumbnailUrl, // CORS 프록시가 적용된 썸네일 URL 사용
                                        width: 100, // 썸네일 너비
                                        height: double.infinity, // 썸네일 높이
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
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
                                          const SizedBox(height: 4),
                                          Text(
                                            '조회수 ${_formatCount(video['viewCount'])}', // 조회수 포맷팅
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '좋아요 ${_formatCount(video['likeCount'])}', // 좋아요 포맷팅
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
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

                      // 페이지네이션 메뉴
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(totalPages, (index) {
                            final pageNumber = index + 1;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  currentPage = pageNumber;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: currentPage == pageNumber
                                      ? Colors.blue
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  pageNumber.toString(),
                                  style: TextStyle(
                                    color: currentPage == pageNumber
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(String? countStr) {
    final count = int.tryParse(countStr ?? '0') ?? 0;
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
