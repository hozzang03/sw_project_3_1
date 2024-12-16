// youtube_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

// YouTube API 키를 여기에 입력하세요.
const String apiKey = 'AIzaSyD0LNXMv6hd9dlcUxUcHerlEk-dvPur7zQ';

// 제외할 채널명 목록
const List<String> excludedChannelNames = ['깃털유머'];

class YouTubeApiService {
  // 기본적으로 동영상 검색
  Future<List<Map<String, dynamic>>> fetchVideos(String query, {int maxResults = 5}) async {
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=$query&maxResults=$maxResults&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List).cast<Map<String, dynamic>>();

      // videoId 추출
      final videoIds = items.map((item) => item['id']['videoId'] as String).join(',');

      // 조회수 및 좋아요 수 가져오기
      final stats = await _fetchVideoStatistics(videoIds);

      return items.map((item) {
        final videoId = item['id']['videoId'] as String;
        final thumbnails = item['snippet']['thumbnails'] as Map<String, dynamic>? ?? {};
        final defaultThumbnail = thumbnails['default']?['url'] ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

        return {
          'id': {'videoId': videoId},
          'snippet': {
            'title': item['snippet']['title'],
            'channelTitle': item['snippet']['channelTitle'],
            'thumbnails': {'default': {'url': defaultThumbnail}},
          },
          'viewCount': stats[videoId]?['viewCount'] ?? '0',
          'likeCount': stats[videoId]?['likeCount'] ?? '0', // 좋아요 수 추가
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch videos: ${response.body}');
    }
  }

  // 특정 조건에 맞는 동영상 검색
  Future<List<Map<String, dynamic>>> searchFilteredVideos(String query, {int maxResults = 50}) async {
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=$query&maxResults=$maxResults&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final videos = (data['items'] as List).cast<Map<String, dynamic>>();

      // videoId 추출
      final videoIds = videos.map((video) => video['id']['videoId'] as String).join(',');

      // 조회수 및 좋아요 수 가져오기
      final stats = await _fetchVideoStatistics(videoIds);

      // 키워드 필터링
      final keywords = ['간단', '자취', '가성비', '혼자', '저렴', '단돈', '값싼', '한가지', '초보'];
      final filteredVideos = videos.where((video) {
        final snippet = video['snippet'] as Map<String, dynamic>;
        final title = snippet['title'] as String;
        final description = snippet['description'] as String? ?? '';

        // 키워드가 제목이나 설명에 포함되어 있는지 확인
        final hasKeyword = keywords.any((keyword) => title.contains(keyword) || description.contains(keyword));

        // 제외할 채널명에 포함되지 않는지 확인
        final isExcludedChannel = excludedChannelNames.any((excluded) => snippet['channelTitle'].contains(excluded));

        return hasKeyword && !isExcludedChannel;
      }).toList();

      return filteredVideos.map((video) {
        final videoId = video['id']['videoId'] as String;
        final thumbnails = video['snippet']['thumbnails'] as Map<String, dynamic>? ?? {};
        final defaultThumbnail = thumbnails['default']?['url'] ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

        return {
          'id': {'videoId': videoId},
          'snippet': { // snippet 키 추가
            'title': video['snippet']['title'],
            'channelTitle': video['snippet']['channelTitle'],
            'thumbnails': {'default': {'url': defaultThumbnail}},
          },
          'viewCount': stats[videoId]?['viewCount'] ?? '0',
          'likeCount': stats[videoId]?['likeCount'] ?? '0', // 좋아요 수 추가
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch videos: ${response.body}');
    }
  }

  // 조회수 및 좋아요 수 가져오기
  Future<Map<String, dynamic>> _fetchVideoStatistics(String videoIds) async {
    if (videoIds.isEmpty) return {};

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/videos?part=statistics&id=$videoIds&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final stats = <String, dynamic>{};

      for (var item in data['items'] as List) {
        final id = item['id'] as String;
        final statistics = item['statistics'] as Map<String, dynamic>;
        stats[id] = {
          'viewCount': statistics['viewCount'],
          'likeCount': statistics['likeCount'] ?? '0', // 좋아요 수 처리
        };
      }

      return stats;
    } else {
      throw Exception('Failed to fetch video statistics: ${response.body}');
    }
  }

  // HOT 레시피에 대한 조회수 필터링 (100만 이상)
  Future<List<Map<String, dynamic>>> fetchHotRecipes(String query, {int maxResults = 20}) async {
    final videos = await fetchVideos(query, maxResults: maxResults * 2); // 충분한 데이터를 가져오기 위해 2배로 요청
    return videos.where((video) {
      final viewCount = int.tryParse(video['viewCount'] ?? '0') ?? 0;
      final channelTitle = video['snippet']['channelTitle'] as String? ?? '';
      final isExcludedChannel = excludedChannelNames.any((excluded) => channelTitle.contains(excluded));
      return viewCount >= 1000000 && !isExcludedChannel; // 100만 이상 조회수 필터 및 제외 채널 제외
    }).take(maxResults).toList();
  }

  // 오늘의 메뉴 추천에 대한 조회수 필터링 (10만 이상) 및 HOT 레시피 제외
  Future<List<Map<String, dynamic>>> fetchRecommendedMenus(
    String query, {
    int maxResults = 20,
    List<String>? excludedVideoIds,
  }) async {
    final videos = await fetchVideos(query, maxResults: maxResults * 5); // 충분한 데이터를 가져오기 위해 5배로 요청

    // 필터링: 조회수 10만 이상, excludedVideoIds에 포함되지 않음, 제외 채널 제외
    final filteredVideos = videos.where((video) {
      final viewCount = int.tryParse(video['viewCount'] ?? '0') ?? 0;
      final isRecommended = viewCount >= 100000;
      final isExcluded = excludedVideoIds?.contains(video['id']['videoId']) ?? false;
      final channelTitle = video['snippet']['channelTitle'] as String? ?? '';
      final isExcludedChannel = excludedChannelNames.any((excluded) => channelTitle.contains(excluded));
      return isRecommended && !isExcluded && !isExcludedChannel;
    }).toList();

    return filteredVideos.take(maxResults).toList();
  }
}
